import { parseResolveInfo } from "graphql-parse-resolve-info";
import { singleton as arborist } from '../lib/arboristClient';

const authFilterResolver = (resolve, parentArg, args, context, info) => {
  const field = parseResolveInfo(info).name;
  const resources = arborist.listAuthorizedResources(context.jwt);
  // We add the `filters` argument with some SQON which will specify that
  // for results having a `project` field, the `project` must be a the list of
  // approved resources. The list of resources is fetched from arborist using
  // the JWT in the original request.
  if (!('filters' in args)) {
    args.filters = {}
  }
  // Must include "and" operator at top level
  args.filters = { ...args.filters, ...{ op: 'and' } }
  if (!('content' in args.filters)) {
    args.filters.content = []
  }
  // Add operator to the filters checking that the `project` field on the
  // graphql results is in the resources listed by arborist.
  args.filters.content = [
    ...args.filters.content,
    ...[
      {
        op: 'in',
        content: {
          field: 'project',
          value: resources,
        }
      },
    ],
  ]
  return resolve(parentArg, args, context, info);
}

// TODO: need to do this for all of the necessary fields in the schema
export const authFilter = {
  subject: authFilterResolver,
}
