# Forgejo

## Creating a bot user

```bash
forgejo admin user create --username WiemanBot --email bot@wieman.cloud --random-password --must-change-password=false
```

Then generate a scoped token as follows

```bash
forgejo admin user generate-access-token --username WiemanBot --token-name token-0 --scopes "write:repository,read:user,write:issue,read:organization" --raw
```

Make sure to save the access token somewhere
