# distributed-kv-go

A sharded key-value database written in Go, deployed across separate physical machines on a LAN.
Each node stores only the shard of the keyspace it owns, redirects requests it cannot serve, and
can be paired with a read-only replica that syncs from its leader.

Built as coursework for Universidad Tecnológica de Pereira.

> **Attribution.** The core engine (`config`, `db`, `web`, `replication`) comes from the
> open-source project `ravikisha/distributedKV` — which is why the Go module path still points
> there. This repository's contribution is the multi-machine deployment: the shard topology across
> real hosts, the leader/replica setup, the per-node launchers and the operating documentation.

---

## The problem

A single-node key-value store stops being interesting the moment the dataset outgrows one machine,
or the moment that machine goes down. This project addresses both:

- **Capacity** — the keyspace is partitioned so each node holds a fraction of the data.
- **Availability** — each shard can run a read-only replica that keeps serving reads.

The interesting part is not storing a key. It is that **a client can talk to any node and still get
the right answer**, without knowing where the data lives.

---

## How it works

### Sharding

Keys are assigned to shards by hashing the key modulo the number of shards:

```
SET nombre=Juan
      │
      ▼
 hash("nombre") % N  ──▶  shard 1  ──▶  node "Medellin"
```

The committed topology (`sharding-distributed.toml`) defines three shards, named after the cities
where the machines were located: `Pereira` (idx 0), `Medellin` (idx 1), `Cali` (idx 2), each with
one replica address.

### Request redirection

Any node accepts any request. If the hash says the key does not belong to it, the node forwards the
request to the owning node and returns its response. From the client's point of view there is one
database, not three.

### Replication

A node started with `--replica` runs a background loop (`replication.ClientLoop`) that polls its
leader for pending writes via `/next-replication-key`, applies them locally, and acknowledges them
with `/delete-replication-key` so the leader can drop them from its queue. Replicas are opened in
read-only mode.

### Storage

Each node persists to a local [bbolt](https://github.com/etcd-io/bbolt) file — a single-file B+tree
store, so there is no external database to install on every machine.

---

## Architecture

| Component | File | Responsibility |
|---|---|---|
| Entry point | `main.go` | Flag parsing, wiring, HTTP route registration |
| Shard config | `config/config.go` | Parses the TOML topology, resolves the current node's index |
| Storage | `db/db.go` | bbolt-backed get/set, replication queue, read-only enforcement |
| HTTP layer | `web/web.go` | `/get`, `/set`, `/purge`, redirection to the owning shard |
| Replication | `replication/replication.go` | Client loop that pulls and applies the leader's writes |

### HTTP API

| Endpoint | Purpose |
|---|---|
| `GET /get?key=` | Read a key — redirects if the key belongs to another shard |
| `GET /set?key=&value=` | Write a key — redirects if not the owner, rejected on replicas |
| `GET /purge` | Drop keys that no longer belong to this shard after a topology change |
| `GET /next-replication-key` | Used by replicas to pull the next pending write |
| `GET /delete-replication-key` | Acknowledges a replicated write so the leader can drop it |

---

## Running it

Requires Go 1.22+. All machines must be on the same LAN with port 8080 reachable.

**1. Set the topology.** Edit `sharding-distributed.toml` with the real IP of each machine:

```toml
[[shards]]
name = "Pereira"
idx = 0
address = "10.1.2.4:8080"
replicas = ["10.1.2.4:8081"]
```

**2. Start each node** on its own machine, passing its own shard name:

```bash
go run . \
  --db-location=pereira.db \
  --http-addr=0.0.0.0:8080 \
  --config-file=sharding-distributed.toml \
  --shard=Pereira
```

PowerShell launchers for each node are included: `launchPEI.ps1`, `launchMED.ps1`, `launchCALI.ps1`.

**3. Start a replica** (optional):

```bash
go run . \
  --db-location=pereira-replica.db \
  --http-addr=0.0.0.0:8081 \
  --config-file=sharding-distributed.toml \
  --shard=Pereira \
  --replica
```

**4. Use it** from any node — redirection makes the entry point irrelevant:

```bash
curl "http://10.1.2.4:8080/set?key=nombre&value=Juan"
curl "http://10.1.1.4:8080/get?key=nombre"   # different node, same answer
```

`populate.sh` writes a batch of test keys to verify the distribution across shards.

---

## Design trade-offs worth naming

- **No coordinator.** There is no router process and no service discovery: every node holds the
  same topology file, so every node can compute the owner of any key by itself. The cost is that
  the topology is static — changing it means editing the file, restarting nodes and running
  `/purge` to drop keys that moved.
- **`hash(key) % N` is simple and unforgiving.** Changing the number of shards reshuffles most of
  the keyspace. Consistent hashing is the standard fix and the natural next step.
- **Replicas pull, they do not receive.** A read served by a replica can be stale by up to one
  polling interval. The design does not hide this — replicas are explicitly read-only.

---

## Status

Complete as a course project. Not maintained, not intended for production use.

## Contributors

[@ddvillegasn](https://github.com/ddvillegasn) · [@KevinCastro25](https://github.com/KevinCastro25) ·
[@miguelsepul](https://github.com/miguelsepul) — Universidad Tecnológica de Pereira.

Core engine: `ravikisha/distributedKV`.

## Further documentation

`GUIA-COMPLETA.md` and `INSTRUCCIONES-DISTRIBUIDO.md` contain the full step-by-step deployment guide
in Spanish, written for the team members who ran each node.
