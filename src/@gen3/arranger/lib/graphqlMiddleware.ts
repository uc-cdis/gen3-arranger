import { parseResolveInfo } from "graphql-parse-resolve-info";
import { singleton as arborist } from '../lib/arboristClient';
import { singleton as config } from '../lib/config';

// authFilterResolver is a GraphQL middleware function that adds some filters to
// the arguments of a query in order to return only results which are authorized
// according to arborist, according to the JWT which should be present in the
// `context`.
const authFilterResolver = async (resolve, parentArg, args, context, info) => {
  const data = await arborist.listAuthorizedResources(context.jwt);
  console.log(data);
  const resources = data['resources'] || [];
  // We add the `filters` argument with some SQON which will specify that
  // for results having a `project` field, the `project` must be a the list of
  // approved resources. The list of resources is fetched from arborist using
  // the JWT in the original request.
  if (!('filters' in args)) {
    args.filters = {}
  }
  // Filters must include "and" operator at top level
  args.filters = { ...args.filters, ...{ op: 'and' } }
  if (!('content' in args.filters)) {
    args.filters.content = []
  }
  // Add operator to the filters checking that the relevant field on the graphql
  // results is in the resources listed by arborist.
  args.filters.content = [
    ...args.filters.content,
    ...[
      {
        op: 'in',
        content: {
          field: config.authFilterField,
          value: resources.map(config.authFilterFieldParser),
        }
      },
    ],
  ]
  console.log(args.filters.content);
  return resolve(parentArg, args, context, info);
}

// authFilter is a map from types in the graphql schema to functions with a
// particular signature which act as GraphQL middleware.
export const authFilter = {
  Query: {
    [config.authFilterNodeType]: authFilterResolver,
  },
}
