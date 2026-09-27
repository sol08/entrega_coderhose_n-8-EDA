## Proyecto Capstone: Análisis Exploratorio de Datos (EDA) en PostgreSQL

  Este proyecto reproduce el trabajo de un analista de datos sobre un e-comerce. Se diseñó una base relacional en PostgreSQL, se cargaron los datos de clientes, productos y pedidos, se aplicó un proceso de validación y limpieza, y se construyeron consultas SQL orientadas a resolver preguntas de negocio.

  El objetivo de este proyecto de negocio logra transformar datos en infomracion para poder responder: quién compra, cuándo, qué producto no se mueve y qué sostiene realmente los ingresos.

## Cómo ejecutarlo

Requiere PostgreSQL 14 o superior.

## Contenido del repositorio

| Archivo | Contenido |
|---|---|
| `estructura.sql` | Tablas con tipos, claves e índices, y carga de datos |
| `analisis.sql` | Limpieza y las cuatro consultas de análisis, comentadas |
| `README.md` | Este documento |

## Modelo de datos

Tres tablas: `clientes`, `productos` y `pedidos`. Cada pedido referencia a un cliente y a un producto por su ID (clave foránea), en vez de repetir sus datos:

<img width="450" height="441" alt="image" src="https://github.com/user-attachments/assets/f095aa81-a983-427c-ab9f-0fbd58a8a3c2" />

Las fechas se guardan como `DATE` y el dinero como `NUMERIC`

## Las cuatro preguntas

### 1. ¿Quiénes sostienen la facturación?
*`GROUP BY` + `SUM`, con `SUM() OVER ()` para el porcentaje sobre el total*

| Cliente | Ciudad | Pedidos | Gasto total | % del total |
|---|---|---|---|---|
| Lucas Flores | Mar del Plata | 81 | $3.082.000 | 18,0 % |
| Florencia Ramírez | Buenos Aires | 30 | $1.245.700 | 7,3 % |
| Camila Martínez | Rosario | 21 | $1.075.300 | 6,3 % |
| Joaquín Acosta | Buenos Aires | 24 | $861.900 | 5,0 % |
| Diego Fernández | Buenos Aires | 22 | $815.200 | 4,7 % |

  El Top 5 concentra el 41,3 % con solo el 12,5 % de los clientes. El primero sobresale: 1 de cada 5 pedidos del año es suyo, y gasta más del doble que el segundo. Ese volumen sugiere un revendedor más que un consumidor final. Seria de gran informacion identificar quien es.

### 2. ¿Cuándo se vende?
*`DATE_TRUNC` para agrupar por mes, `COALESCE` para no perder los pedidos sin fecha*

| Mes | Pedidos | Ventas |
|---|---|---|
| Ene | 18 | $765.200 |
| Feb | 26 | $1.553.300 |
| Mar | 27 | $981.000 |
| Abr | 26 | $1.371.000 |
| **May** | **54** | **$2.211.200** |
| Jun | 32 | $1.254.300 |
| Jul | 29 | $1.483.800 |
| Ago | 27 | $1.208.100 |
| **Sep** | **20** | **$499.000** |
| Oct | 29 | $1.186.800 |
| **Nov** | **53** | **$2.132.400** |
| **Dic** | **48** | **$1.933.500** |
| Sin fecha | 11 | $582.600 |

  Mayo, Noviembre y Diciembre suman $6,28 M (36,6 % del año). Septiembre cae un 77 % respecto de Mayo. Conviene planificar stock y logística para los picos.

### 3. ¿Qué no se mueve?
*`LEFT JOIN` desde productos, para no perder los que nunca se vendieron*

| Producto | Categoría | Unidades | Ingreso |
|---|---|---|---|
| Bicicleta rodado 29 | Deportes | 1 | $315.000 |
| Colchoneta de yoga | Deportes | 2 | $24.000 |
| Aspiradora robot | Hogar | 3 | $630.000 |

  Vender poco no es lo mismo que aportar poco: la bicicleta, con una sola venta, factura 13 veces más que la colchoneta. Sin embargo, solo la colchoneta combina baja rotación con ticket bajo.

### 4. ¿Qué producto lidera cada categoría?
*`RANK() OVER (PARTITION BY categoria ORDER BY cant_pedidos DESC)` sobre una subconsulta agrupada*

| Categoría | Pedidos | Ingreso | % del total |
|---|---|---|---|
| Indumentaria | 90 | $5.627.200 | 32,8 % |
| Electrónica | 73 | $3.922.900 | 22,9 % |
| Hogar | 71 | $2.746.900 | 16,0 % |
| Deportes | 49 | $2.678.600 | 15,6 % |
| Libros | 117 | $2.186.600 | 12,7 % |

  El líder en volumen casi nunca es el líder en facturación: en "Indumentaria", las zapatillas running tienen la mitad de pedidos que la remera pero facturan más que cualquier otro producto del catálogo. "Libros" es el extremo opuesto: la categoría con más pedidos es la que menos factura.

## Resumen

1. Un solo cliente aporta el 18 % de la facturación: el mayor riesgo del negocio
2. Mayo, Noviembre y Diciembre venden el 37 % del año; Septiembre es el mes más flojo
3. De los productos con menor rotación, solo uno tiene además ticket bajo; los otros dos valen la pena igual
4. La categoria "Libros" genera más pedidos que cualquier categoría, pero es la que menos factura; "Indumentaria" es la que más aporta

## Limitaciones

- Se mide ingreso, no rentabilidad: sin costos no se sabe qué categoría deja más margen
- Es un solo año: no confirma tendencia
- El 6,5 % de ingresos imputados asume que no hubo descuento sobre el precio de lista
- Cada pedido tiene un único producto: no se analiza qué se compra junto


