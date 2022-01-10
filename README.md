
[![codecov](https://codecov.io/gh/RPMTW/RPMTW-Server/branch/main/graph/badge.svg?token=NEAZZJO2M6)](https://codecov.io/gh/RPMTW/RPMTW-Server)
## RPMTW API Server

RPMTW API 後端伺服器，使用 Dart 語言開發。

### Running with the Dart SDK

You can run the example with the [Dart SDK](https://dart.dev/get-dart)
like this:

```
$ dart run bin/server.dart
```

### Running with Docker

If you have [Docker Desktop](https://www.docker.com/get-started) installed, you
can build and run with the `docker` command:

```
$ docker build . -t rpmtw_server
$ docker run -it -p 8080:8080 rpmtw_server
```


### 相關連結
[Dart 用戶端函式庫](https://github.com/RPMTW/RPMTW-API-Client)  
[帳號系統使用者界面](https://github.com/RPMTW/RPMTW-Account-UI)  
[RPMTW Minecraft 維基百科](https://github.com/RPMTW/RPMTW-Wiki)