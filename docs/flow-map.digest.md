# flow-map.digest — Agent OS Core (generado; fuente: docs/critical-flows.md)
# líneas: 4 flujos · no editar a mano

1|L2|🟡|Bind vs. destino de proxy inverso|tarea:T-098
2|L1|⬜|Propagación de assets core → hijo|tarea:T-101
3|L3|🟡|Cierre de tarea honesto|tarea:T-100
4|L3|🟡|Promoción de rama a destino|tarea:T-101

relaciones:
  3->4
  2->3

niveles:
  L1=Sistema
  L2=Contenedor / subsistemas
  L3=Componente / scripts
  L4=Código
