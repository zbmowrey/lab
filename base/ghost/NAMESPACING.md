# Namespacing

This particular project required some jumping through hoops to get the namespacing right.

The Percona MySQL Operator only watches the `mysql-operator` namespace (where it's deployed),
and unfortunately, Kustomize overrides namespaces rather aggressively. 

I would have hoped that I could specify a namespace in kustomization.yaml, and then it would
apply that namespace as a default, allowing me to override in any specific resource. Testing
has confirmed that this is not the case, and that the namespace is forced to match for all
resources. 

---

So the convention for any app using the MySQL Operator is to AVOID using the `namespace` 
field in kustomization.yaml. Instead, each resource should specify its namespace explicitly.
There may be a means to tell the Operator to watch multiple namespaces, but I was unable to
identify a successful route after an hour of digging. Might be worth a second look to avoid
the pain here, but for now, I have a workable solution. 

---

This will allow us to build and deploy the MySQL related resources in the `mysql-operator`
namespace, while still allowing other resources to be deployed in their own namespaces.

