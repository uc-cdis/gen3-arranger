# TL;DR

Gen3 service translates GraphQL requests to Elastic Search queries via the [arranger](https://www.npmjs.com/package/@arranger/server) API.

## License

The @arranger code is licensed under the [AGPL](https://github.com/overture-stack/arranger/blob/master/LICENSE).

## Scripts

Note that the code under `src/` is [typescript](https://www.typescriptlang.org/), 
so there's a compile step
to generate the javascript code under `lib/`, `bin/`, and `spec/`.
The following scripts are registered in `package.json`:

```
npm run compile
npm run test
npm run eslint
npm start
```

## Configuration

Override the default configuration with environment variables:

* `GEN3_ES_ENDPOINT` - default is `esproxy-service`
* `GEN3_PROJECT_ID` - default is `dev` - arranger interacts with the ES index with name `arranger-projects-$Id`

## Docker

(Quay)[https://quay.io/repository/cdis/arranger]

