import httpClient
import os
import json
import strformat
import base64
import strutils

type
  User = object
    username: string
    password: string
    clientId: string
    clientSecret: string

  Token = object
    access_token: string
    expires_in: int
    scope: string
    token_type: string

  Session = object
    user: User
    token: Token
    client: HttpClient

  IdentityInfo = object
    id: string
    created: float
    created_utc: float
    has_mail: bool
    name: string

let NoToken = Token(access_token: "",
                    expires_in: -1,
                    scope: "",
                    token_type: "")

proc getBotUser() : User =
  let
    username = os.getEnv("REDDIT_USER")
    password = os.getEnv("REDDIT_PASS")
    clientId = os.getEnv("REDDIT_CLIENT_ID")
    clientSecret = os.getEnv("REDDIT_CLIENT_SECRET")

  result = User(username: username,
                password: password,
                clientId: clientId,
                clientSecret: clientSecret)

proc getAuthToken(client: HttpClient, user: User) : Token =
  var
    data = newMultipartData()

  data.add("grant_type", "password")
  data.add("username", user.username)
  data.add("password", user.password)

  let
    res = client.postContent("https://www.reddit.com/api/v1/access_token", multipart=data)

  result = parseJson(res).to(Token)

proc newSession(user: User) : Session =
  var client = newHttpClient(fmt"Agent: {user.username}")
  let
    encoded = base64.encode(fmt"{user.clientID}:{user.clientSecret}")
    auth = fmt"Basic {encoded}"

  client.headers["Authorization"] = auth
  result = Session(user: user,
                   token: NoToken,
                   client: client)

proc saveToken(session: var Session, token: Token) =
  session.token = token
  # TODO: Save token to file


proc init(session: var Session) =
  # TODO: Check for persisted and valid token before fetching new one
  let
    token = session.client.getAuthToken(session.user)
    auth = fmt"bearer {token.access_token}"

  session.saveToken(token)
  session.client.headers["Authorization"] = auth

proc getIdentityInfo(session: Session) : IdentityInfo =
  assert session.token != NoToken

  let res = session.client.getContent("https://oauth.reddit.com/api/v1/me")
  result = parseJson(res).to(IdentityInfo)

when isMainModule:
  let bot = getBotUser()
  var session = newSession(bot)

  session.init()
  echo session.getIdentityInfo()

