# Roadmap

| Phase | Focus | Status |
|---|---|---|
| 0 | Repo and documentation foundation | ✅ Done |
| 1 | Isolated SDN: zone, vnet, subnet, SNAT | ✅ Done: `sc300` zone, vnet, subnet and SNAT are live on all nodes; sevro chosen as the lab host |
| 2 | Isolation verified: tests T1 to T6 run and recorded | 🗓️ Planned |
| 3 | Machines: dc01, ws01, ws02 provisioned as plain Windows; AD, DNS and DHCP configured by hand during the course | ⏳ In progress: machines provisioned, roles not configured |
| 4 | Entra tenant, custom domain, sync server, hybrid join | 🗓️ Planned |
| 5 | Exam labs: authentication, Conditional Access, PIM | 🗓️ Planned |
| 6 | Exam labs: workload identities and governance | 🗓️ Planned |

Phase order follows dependency: nothing syncs to a real tenant until the boundary is proven.
