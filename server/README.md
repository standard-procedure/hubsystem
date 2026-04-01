# HubSystem Server

This server is a communication and productivity hub for the HubSystem.  

Users of HubSystem will be human or synthetic.  The system makes no distinction between the two.  

The web user interface is designed for humans, the JSON API is designed for synthetics.  

There is **feature parity** between the two.  

## Web User Interface

### High level information architecture

```
Dashboard: search, tiles, status indicators, superintendent
|    
|
+--- Messages: search, unread messages, conversations
|
|
+--- Projects: search, active tickets, projects
|
|
+--- Documents: search, folders
|
|
+--- Terminals: search, active terminals
|
|
+--- Users: search, users
|
|
+--- Settings: profile, security credentials, security passes
```

## JSON API
