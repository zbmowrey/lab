# [ADR-0001] Sensitive and Secret Data Management

## Status

Draft

---

## Context

Describe the context or problem motivating this decision.

Example:

> We currently deploy all our services into the default namespace. This creates a risk of conflicting resources, complicated RBAC management, and makes it difficult to isolate environments for testing and staging.

---

## Decision

Clearly state the decision taken.

Example:

> We will adopt a naming convention for namespaces following the pattern `<team>-<environment>`, and enforce this via CI checks in our Kubernetes manifests.

---

## Consequences

List the positive and negative consequences of this decision.

Example:

- **Positive:**
    - Improved isolation between environments
    - Better RBAC granularity
    - Easier cost allocation
- **Negative:**
    - Existing resources must be migrated
    - CI pipeline complexity will increase slightly

---

## Alternatives Considered

Describe any significant alternative options you considered and why you didn’t choose them.

Example:

- Keep using a single namespace:
    - **Rejected** because of poor separation of concerns.
- Use one namespace per microservice:
    - **Rejected** because it creates too many namespaces and complicates networking.

---

## Related Decisions

Link to any related ADRs.

Example:

> See also:
>
> - [ADR-0002 Namespace Labeling Standard](adr-0002-namespace-labeling-standard.md)

---

## Notes

Any extra notes, references, or external resources.

Example:

> Kubernetes documentation on namespaces: https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/
