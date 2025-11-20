# Script para lanzar todos los nodos de la base de datos distribuida

# Iniciar nodos principales
Start-Process powershell -ArgumentList "-NoExit", "-Command", ".\distributedKV.exe --db-location=Mumbai.db --http-addr=127.0.0.2:8080 --config-file=sharding.toml --shard=Mumbai"
Start-Process powershell -ArgumentList "-NoExit", "-Command", ".\distributedKV.exe --db-location=Delhi.db --http-addr=127.0.0.3:8080 --config-file=sharding.toml --shard=Delhi"
Start-Process powershell -ArgumentList "-NoExit", "-Command", ".\distributedKV.exe --db-location=Chennai.db --http-addr=127.0.0.4:8080 --config-file=sharding.toml --shard=Chennai"
Start-Process powershell -ArgumentList "-NoExit", "-Command", ".\distributedKV.exe --db-location=Bangalore.db --http-addr=127.0.0.5:8080 --config-file=sharding.toml --shard=Bangalore"

# Iniciar réplicas
Start-Process powershell -ArgumentList "-NoExit", "-Command", ".\distributedKV.exe --db-location=Mumbai-r.db --http-addr=127.0.0.22:8080 --config-file=sharding.toml --shard=Mumbai --replica"
Start-Process powershell -ArgumentList "-NoExit", "-Command", ".\distributedKV.exe --db-location=Delhi-r.db --http-addr=127.0.0.33:8080 --config-file=sharding.toml --shard=Delhi --replica"
Start-Process powershell -ArgumentList "-NoExit", "-Command", ".\distributedKV.exe --db-location=Chennai-r.db --http-addr=127.0.0.44:8080 --config-file=sharding.toml --shard=Chennai --replica"
Start-Process powershell -ArgumentList "-NoExit", "-Command", ".\distributedKV.exe --db-location=Bangalore-r.db --http-addr=127.0.0.55:8080 --config-file=sharding.toml --shard=Bangalore --replica"

Write-Host "Todos los nodos han sido iniciados en ventanas separadas"
Write-Host "4 nodos principales + 4 réplicas = 8 procesos en total"
