
1. LIMPIEZA: DIAGNÓSTICO DE NULOS EN COLUMNAS CRÍTICAS
  
  ---Aca lo que buscamos es ver cuantos pedidos tienen el precio o la fecha vacios
  ---Entonces lo que hacemos en contar toda las filas con dato, ignorando los NULL
  ---La diferencia entre ambos conteos es la cantidad de nulos que hay y lo expresamos en porcentaje
  
SELECT
    COUNT(*) AS total_pedidos,        
    COUNT(*) - COUNT(precio_unitario) AS pedidos_sin_precio,   
    COUNT(*) - COUNT(fecha_pedido) AS pedidos_sin_fecha,   
    ROUND(100 * (COUNT(*) - COUNT(precio_unitario)) / COUNT(*), 1) AS pct_sin_precio,  
FROM capstone_EDA.pedidos;                                             

2. LIMPIEZA: DATOS LISTOS PARA ANALIZAR

  ---Aca los que se busca es hacer una limpieza de datos de una sola vez para poder trabajar mas comodos en las consultas siguientes
  ---Se crea una vista para ello, dejando el precio completo y el ingreso ya calculado
  ---Para el precio usamos el precio de lista, en caso de que sea NULL, sino se usa el propio
  ---Para la fecha la dejamos nula, porque sino esa puede impactar en el reporte de estacionalidad desviando el comportamiento
  ---Se calcual el ingreso = cantidad * precio

CREATE VIEW pedidos_limpios AS        
SELECT
    p.pedido_id,
    p.cliente_id,
    p.producto_id,
    p.fecha_pedido,                                
    p.cantidad,
    COALESCE(p.precio_unitario, pr.precio_lista) AS precio_unitario,  
    p.cantidad * COALESCE(p.precio_unitario, pr.precio_lista) AS ingreso,          
FROM capstone_EDA.pedidos p
JOIN capstone_EDA.productos pr USING (producto_id);       


---Hacemos un control de calidad buscando quqe ningun precio quede nulo despues de la limpieza
---Se cuentas las filas de la vista que aun tengan precio NULL, si el COALESCE cubrio todos los casos deberia ser 0

SELECT COUNT(*) AS precios_nulos_restantes         
FROM pedidos_limpios                               
WHERE precio_unitario IS NULL;                


 3. TOP 5 CLIENTES POR GASTO TOTAL

   ---Se busca ver cuales son los cino clientes que mas deinero gastaron, cuantos pedidos relaizaron y que % de la facturacion representan
   ---Este analisis es importante porque se ve donde estan concentrados los ingresos y que postura se toma frente a eso
   ---Se une en este caso la vista creada con los datos limpios y la tabla de clientes; y agrupamos por clientes
   ---Para cada uno se cuenta la cantidad de pedidos y se suman los ingresos, ademas se calcual el % sobre el total usando una window fx

SELECT
    c.cliente_id,
    c.nombre,                                    
    c.ciudad,
    COUNT(*) AS cant_pedidos,               
    SUM(pl.ingreso) AS gasto_total,               
    ROUND(100 * SUM(pl.ingreso) / SUM(SUM(pl.ingreso)) OVER (), 1) AS pct_del_total 
FROM pedidos_limpios pl                           
JOIN clientes c USING (cliente_id)                
GROUP BY c.cliente_id, c.nombre, c.ciudad          
ORDER BY gasto_total DESC                         
LIMIT 5;                                        

4. VENTAS TOTALES POR MES

  ---Buscamos cuantos pedidos y cuanto dinero se vendio en cada mes del año, con lo cual podemos detectar los meses de valle o picos de venta
  ---Agrupamos por mes, contamos pedidos y sumamos las ventas respectivamente
  
SELECT
    COALESCE(                                      
        TO_CHAR(DATE_TRUNC('month', fecha_pedido), 'YYYY-MM'), 
        'Sin fecha') AS mes,                      
    COUNT(*) AS cant_pedidos,                 
    SUM(ingreso) AS ventas_totales                
FROM pedidos_limpios
GROUP BY DATE_TRUNC('month', fecha_pedido)        
ORDER BY DATE_TRUNC('month', fecha_pedido) NULLS LAST; 

5. LOS 3 PRODUCTOS MENOS VENDIDOS
  
  ---Buscamos los 3 productos con menos unidades vendidas y el ingreso que generaron
  ---De esta manera logramos detectar productos que no rotan; que no necesariamente significa que el ingreso sea poco
  ---Partimos de la tabla de productos y usamos un LEFT JOIN para conservar los productos que no tengan pedidos
  ---Se suman las unidades e ingreso por producto y se ordena de menos a mas

SELECT
    pr.producto_id,
    pr.nombre,
    pr.categoria,
    COALESCE(SUM(pl.cantidad), 0) AS unidades_vendidas,   
    COALESCE(SUM(pl.ingreso), 0)  AS ingreso_generado   
FROM productos pr                                  
LEFT JOIN pedidos_limpios pl USING (producto_id)   
GROUP BY pr.producto_id, pr.nombre, pr.categoria  
ORDER BY unidades_vendidas ASC, ingreso_generado ASC  
LIMIT 3;                                          


6. RANKING DE PRODUCTOS DENTRO DE CADA CATEGORÍA
  
  ---Finalmente, buscamos el puesto de cada producto dentro de su categoria para ver que prodcuto lidera cada segmento
  ---Para ello se agrupa por categoria y producto, junto con sus ingresos y se aplica RANK como una window fx
  ---Y se hace un PARTITION BY para separar por categoria y se ordena de forma DESC

SELECT
    categoria,
    nombre AS producto,
    cant_pedidos,
    ingreso,
    RANK() OVER (                                 
        PARTITION BY categoria                     
        ORDER BY cant_pedidos DESC                
    ) AS ranking_en_categoria                   
FROM (                                           
    SELECT pr.categoria, pr.nombre,
           COUNT(*)        AS cant_pedidos,        
           SUM(pl.ingreso) AS ingreso             
    FROM pedidos_limpios pl
    JOIN productos pr USING (producto_id)         
    GROUP BY pr.categoria, pr.nombre             
) t                                              
ORDER BY categoria, ranking_en_categoria;      

