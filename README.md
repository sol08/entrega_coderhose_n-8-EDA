# Capstone: Análisis Exploratorio de Datos en PostgreSQL

Análisis de las ventas 2025 de una tienda online argentina para responder: **¿de qué clientes, productos y momentos del año depende realmente la facturación, y dónde hay riesgo u oportunidad?**

> **Sobre los datos:** el dataset es **sintético** (semilla fija, reproducible), generado para este proyecto: 40 clientes, 20 productos en 5 categorías y 400 pedidos de 2025. Se le incorporaron nulos deliberadamente para practicar la limpieza. Los hallazgos ilustran el método de análisis; no describen un negocio real.

## Problema de negocio

La dirección quiere decidir dónde poner presupuesto de marketing y stock. Para eso necesita saber (1) qué tan concentrada está la facturación en pocos clientes, (2) cuándo se vende, (3) qué productos no rotan y (4) qué categorías y productos sostienen el negocio.

## Contenido del repositorio

| Archivo | Qué hace |
|---|---|
| `estructura.sql` | Crea las tablas `clientes`, `productos` y `pedidos` (con claves, restricciones e índices) y carga los datos. |
| `analisis.sql` | Verifica tipos, diagnostica y limpia nulos, y resuelve las 4 consultas de análisis, comentadas. |
| `README.md` | Este documento. |

## Cómo ejecutarlo

Requiere PostgreSQL 14 o superior (probado en 16).

```bash
createdb capstone_project
psql -v ON_ERROR_STOP=1 -d capstone_project -f estructura.sql
psql -v ON_ERROR_STOP=1 -d capstone_project -f analisis.sql
```

`ON_ERROR_STOP=1` frena la ejecución ante el primer error en lugar de seguir con datos a medias. Ambos scripts se pueden volver a correr: `estructura.sql` recrea las tablas y `analisis.sql` usa `CREATE OR REPLACE VIEW`.

## Limpieza de datos

| Problema | Cantidad | Tratamiento |
|---|---|---|
| `precio_unitario` nulo | 26 pedidos (6,5 %) | `COALESCE` con el `precio_lista` del producto |
| `fecha_pedido` nula | 11 pedidos (2,8 %) | Se deja nula y se reporta aparte como "Sin fecha" |

**Por qué estas decisiones.** Descartar los pedidos sin precio habría subestimado la facturación en un 6,5 %; usar el precio de lista es la mejor estimación disponible, con el costo de sobrestimar levemente si hubo descuentos. Con las fechas no se imputó nada: inventar una fecha distorsionaría justo lo que se quiere medir, la estacionalidad. Los tipos se verificaron contra `information_schema`: fechas como `DATE` y dinero como `NUMERIC(12,2)`, nunca `FLOAT`.

**Cuánto condiciona esto las conclusiones:** $1.108.000 de los $17.162.200 facturados (6,5 %) son estimados, y $582.600 (3,4 %) no se pueden ubicar en ningún mes. Es un margen acotado: no cambia ningún ranking de los que siguen, pero conviene que quien cargue los pedidos corrija el origen del dato.

## Hallazgos e interpretación

### 1. La facturación depende demasiado de un solo cliente

| Cliente | Ciudad | Pedidos | Gasto | % del total |
|---|---|---|---|---|
| Lucas Flores | Mar del Plata | 81 | $3.082.000 | 18,0 % |
| Florencia Ramírez | Buenos Aires | 30 | $1.245.700 | 7,3 % |
| Camila Martínez | Rosario | 21 | $1.075.300 | 6,3 % |
| Joaquín Acosta | Buenos Aires | 24 | $861.900 | 5,0 % |
| Diego Fernández | Buenos Aires | 22 | $815.200 | 4,7 % |

Los 5 mejores clientes (12,5 % de la base de 40) aportan el 41,3 % de los ingresos, pero lo llamativo es el primero: **un solo cliente explica el 18 % de la facturación y el 20 % de todos los pedidos**, más del doble que el segundo. Con esa forma de distribución, perderlo tendría un impacto directo en los resultados. Antes de armar un programa de fidelización hay que averiguar quién es: por volumen (81 pedidos en un año) podría ser un revendedor o una cuenta compartida, y en ese caso corresponde tratarlo como cliente mayorista, con condiciones y seguimiento propios, en lugar de como comprador individual.

### 2. Tres meses concentran más de un tercio del año

Mayo ($2,21 M), noviembre ($2,13 M) y diciembre ($1,93 M) suman $6,28 M, el 36,6 % de la facturación anual. Mayo coincide con eventos de descuento como el Hot Sale, y noviembre-diciembre con Black Friday y las fiestas. En el otro extremo, **septiembre fue el peor mes ($499 mil), 77 % menos que mayo**, con solo 20 pedidos.

Implicancias: el stock y la logística deben dimensionarse para esos picos, y septiembre es el mes donde una campaña propia tiene más margen para mover la aguja porque la demanda espontánea es mínima. Hay que tener presente que estas cifras son de un solo año; con un único ciclo no se puede distinguir estacionalidad estable de un caso puntual.

### 3. Los productos menos vendidos no son todos el mismo problema

| Producto | Unidades | Ingreso |
|---|---|---|
| Bicicleta rodado 29 | 1 | $315.000 |
| Colchoneta de yoga | 2 | $24.000 |
| Aspiradora robot | 3 | $630.000 |

Vender poco no equivale a aportar poco. La bicicleta y la aspiradora son productos de ticket alto: con 1 y 3 unidades generan más ingreso que la colchoneta (ticket de $12.000) con 2. Sacarlos del catálogo por su baja rotación sería un error; lo razonable es mantenerlos y evaluar si el capital inmovilizado en stock se justifica. **La colchoneta sí es el candidato real a liquidación o a venderse en combo** (por ejemplo con las mancuernas, de la misma categoría y que rotan bien): combina baja rotación y bajo ticket.

### 4. Volumen y facturación cuentan historias distintas

Por facturación lidera Indumentaria (32,8 %), seguida de Electrónica (22,9 %). **Libros tiene la mayor cantidad de pedidos (117) pero es la categoría que menos factura (12,7 %)**: atrae tráfico, pero no mueve el resultado.

El ranking con `RANK()` dentro de cada categoría lo confirma a nivel producto. En Indumentaria, la remera deportiva lidera en pedidos (36) pero las zapatillas running, con 19 pedidos, son el producto que más factura de todo el catálogo ($2,27 M). Algo similar ocurre en Electrónica, donde el parlante portátil (21 pedidos) factura más del doble que el cargador que lidera el ranking (30 pedidos). Rankear solo por cantidad esconde a los productos que realmente sostienen los ingresos. También se observa un empate en Hogar (sábanas y cafetera, 14 pedidos cada uno, ambos en la posición 2), caso en que `RANK()` respeta la igualdad y salta a la posición 4, algo que `ROW_NUMBER()` no haría.

## Conclusiones estratégicas

1. **Reducir la dependencia del cliente principal**: identificar su perfil y definir un tratamiento específico; en paralelo, ampliar la base de compradores frecuentes, que hoy aporta poco individualmente.
2. **Planificar en torno a mayo, noviembre y diciembre**: stock y capacidad de entrega para los picos; acciones de demanda propias en septiembre.
3. **No decidir el catálogo por unidades vendidas**: usar el ingreso junto con el volumen. Liquidar o combinar la colchoneta; conservar bicicleta y aspiradora.
4. **Priorizar promoción en Indumentaria y Electrónica**, donde cada pedido rinde más, y usar Libros como producto de entrada más que como fuente de margen.

## Limitaciones

- Datos sintéticos de un solo año; los patrones son ilustrativos.
- Se mide **ingreso**, no rentabilidad: sin costos no se puede afirmar qué categoría deja más margen.
- El 6,5 % de ingresos con precio imputado asume que no hubo descuento en esos pedidos.
- Cada pedido contiene un único producto, por lo que no se analiza el ticket de compra con varios ítems.

