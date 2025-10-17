# Memory for AI Agents

## RULES

- When developing I'm running the frontend and backend with hot reload so just make changes to the code and I can see if those changes worked or not
- Read docs/PRD.md to get a high-level understanding of the app / project
- Read docs/DB_schema.md to learn about the database design
- Read db/init/init.js to know the real structure of static DB data, specifically the seasons collection
- When implementing a new feature or starting a new session it is a good idea to first read docs/PRD.md, docs/DB_schema.md, and db/init/init.js to know the product and the database architecture
- Don't worry about unit tests or integration tests for now
- Don't use SnackBar's in flutter
- When working on core logic don't add unnecessary type checking and default values. Validate at the edges, trust on the inside
- Do not have code that fails silently. Allow things to fail if something is wrong
- Never use dynamic imports (unless asked to) like `await import(..)`
- Never cast to `any`
- Do not add extra defensive checks or try/catch blocks
- If you need to run python commands in the backend, use uv

## COMMANDS

- The pre-commit is already setup. Simply run `pre-commit run -a` from the root of the repo
  - Ask me for permission to run this exact command if you encounter a permission error
