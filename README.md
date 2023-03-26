This action will fetch all the collaborators and teams of the repository and will do the following 

if the team does not exist in Port it will automatically create it
it will also assign it to an entity with an identifier that equals to the repository name, and

if a blueprint with the identifier `Service` is not exist within Port it will be created with the minimal required properties, if you already have a blueprint with `Servuce` identifier you can add the following property to the blueprint.

```json showLineNumbers
"collaborators": {
    "type": "array",
    "title": "Collaborators",
    "items": {
        "type": "string",
        "format": "user"
    }
}
```

to make this work please make sure to add the following secrets

* `PORT_CLIENT_ID`: can be extracted from Port
* `PORT_CLIENT_SECRET`: can be extracted from Port
* `GIT_ADMIN_TOKEN`: create a new admin token and give it to the workflow