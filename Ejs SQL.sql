
/*1. Mostrar el código, razón social de todos los clientes cuyo límite de crédito sea mayor o
igual a $ 1000 ordenado por código de cliente.
*/
select clie_codigo, clie_razon_social 
from Cliente where clie_limite_credito>=1000 order by clie_codigo
/*2. Mostrar el código, detalle de todos los artículos vendidos en el año 2012 ordenados por
cantidad vendida.*/

select prod_codigo, prod_detalle, sum(item_cantidad) as Cantidad_Vendida from Item_Factura 
join Producto on prod_codigo = item_producto 
join Factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
where YEAR(fact_fecha)=2012
group by prod_codigo, prod_detalle
order by Cantidad_Vendida


/*3. Realizar una consulta que muestre código de producto, nombre de producto y el stock
total, sin importar en que deposito se encuentre, los datos deben ser ordenados por
nombre del artículo de menor a mayor.
*/
select prod_codigo,prod_detalle,isnull(SUM(stoc_cantidad),0) as Cantidad_Total
from Producto
left join stock on prod_codigo = stoc_producto --muestra incluso los productos sin stock
--join stock on prod_codigo = stoc_producto --solo muestra productos con stock
group by prod_codigo,prod_detalle 
order by 2
/*
4. Realizar una consulta que muestre para todos los artículos código, detalle y cantidad de
artículos que lo componen. Mostrar solo aquellos artículos para los cuales el stock
promedio por depósito sea mayor a 100.
*/

select prod_codigo, prod_detalle, count(comp_componente) as 'Cant articulos'
from producto
left join Composicion on prod_codigo=comp_producto
group by prod_codigo, prod_detalle
having prod_codigo in (select stoc_producto from STOCK group by stoc_producto having avg(stoc_cantidad)>100)
order by count(comp_componente) desc


/*
5. Realizar una consulta que muestre código de artículo, detalle y cantidad de egresos de
stock que se realizaron para ese artículo en el año 2012 (egresan los productos que
fueron vendidos). Mostrar solo aquellos que hayan tenido más egresos que en el 2011.
*/
select prod_codigo, prod_detalle, sum(item_cantidad) as 'Cant egresos stock' 
from Producto 
join Item_Factura on prod_codigo = item_producto
join Factura on fact_tipo+fact_sucursal+fact_numero=item_tipo+item_sucursal+item_numero 
where year(fact_fecha) = 2012
group by prod_codigo, prod_detalle
having sum(item_cantidad) > (select sum(item_cantidad) from Item_Factura 
join Factura on fact_tipo+fact_sucursal+fact_numero=item_tipo+item_sucursal+item_numero 
where year(fact_fecha) = 2011 and prod_codigo = item_producto ) 


/*6. Mostrar para todos los rubros de artículos código, detalle, cantidad de artículos de ese
rubro (o sea cuantos tipos de articulos hay para cada rubro) 
y stock total de ese rubro de artículos. 
Solo tener en cuenta aquellos artículos que tengan un stock mayor al del artículo ‘00000000’ en el depósito ‘00’.*/
select rubr_id, rubr_detalle, count(distinct prod_codigo) as 'Cant prods x rubro', sum(stoc_cantidad) as 'stock total rubro'
from rubro 
join producto on prod_rubro = rubr_id
join stock on prod_codigo = stoc_producto
where (select sum(stoc_cantidad) from STOCK where prod_codigo = stoc_producto) > 
	  (select  stoc_cantidad from stock where stoc_deposito='00' and stoc_producto = '00000000')
group by rubr_id, rubr_detalle


/*7.Generar una consulta que muestre para cada artículo código, detalle, mayor precio
menor precio y % de la diferencia de precios (respecto del menor Ej.: menor precio =
10, mayor precio =12 => mostrar 20 %). Mostrar solo aquellos artículos que posean
stock.*/
select prod_codigo, prod_detalle, max(item_precio) as 'Mayor precio', 
	   min(item_precio) as 'Menor precio',
	   concat(cast((max(item_precio)-min(item_precio))*100/min(item_precio)as decimal(8,2)),'%' )as '% diferencia de precios'
from producto
join item_factura on item_producto = prod_codigo 
join stock on prod_codigo = stoc_producto
where (select sum(stoc_cantidad) from STOCK where prod_codigo = stoc_producto ) > 0
group by  prod_codigo, prod_detalle


/*8. Mostrar para el o los artículos que tengan stock en todos los depósitos, nombre del
artículo, stock del depósito que más stock tiene.*/
select prod_detalle as 'Detalle producto', max(stoc_cantidad) as 'Stock maximo en un deposito'
from producto 
join stock on prod_codigo = stoc_producto
group by prod_codigo, prod_detalle
having count(*) = (select count(*) from deposito) 
--HAVING asegura que solo se muestren los productos cuyo conteo de registros coincide con el total de registros en DEPOSITO.

/*9. Mostrar el código del jefe, código del empleado que lo tiene como jefe, nombre del
mismo y la cantidad de depósitos que ambos tienen asignados.  */
-- la ulitma columna es ambigua, aca 2 opciones:
select empl_jefe as 'Çódigo jefe', 
	   empl_codigo as 'Código empleado', 
	   (rtrim(empl_nombre)+' '+rtrim(empl_apellido)) as 'Nombre empleado',
	   count(*) as 'Suma cant depositos' -- cant de depositos de ese empleado + cantidad depositos del jefe
from Empleado
join DEPOSITO on depo_encargado = empl_codigo or depo_encargado = empl_jefe

where (empl_jefe is not null)
group by empl_jefe, empl_codigo, empl_nombre, empl_apellido
order by 2

--
SELECT empl_jefe 'Codigo Jefe', empl_codigo 'Codigo Empleado',
(SELECT COUNT(*) FROM DEPOSITO WHERE depo_encargado=empl_jefe) 'Depositos Asignados Jefe' ,
(SELECT COUNT(*) FROM DEPOSITO WHERE depo_encargado=empl_codigo)'Depositos Asignados Empleado',
((SELECT COUNT(*) FROM DEPOSITO WHERE depo_encargado=empl_jefe)+(SELECT COUNT(*) FROM DEPOSITO WHERE depo_encargado=empl_codigo)) as 'total' 
--La ultima columna es distinta que la suma del otro porque acá hay subconsulta
--Esta opcion permite diferenciar a quien corresponde cada deposito
FROM Empleado
where empl_jefe is not null
order by 1

/*10. Mostrar los 10 productos más vendidos en la historia y también los 10 productos menos
vendidos en la historia. Además mostrar de esos productos, quien fue el cliente que
mayor compra realizo. */
select prod_codigo, prod_detalle, 
(select top 1 (clie_codigo) from Cliente join Factura on fact_cliente = clie_codigo JOIN Item_Factura ON fact_numero=item_numero 
WHERE prod_codigo=item_producto group by fact_cliente, clie_codigo order by sum(item_cantidad) desc ) as 'clie 1',

(select top 1 fact_cliente from Factura join Item_Factura on fact_tipo+fact_sucursal+fact_numero=item_tipo+item_sucursal+item_numero 
where item_producto = prod_codigo group by fact_cliente order by sum(item_cantidad) desc) 
as 'cliente 2'
from Producto
where prod_codigo in
(select top (10) item_producto from Item_Factura  group by item_producto order by SUM(item_cantidad) desc)
 or prod_codigo in
(select top (10) item_producto from Item_Factura group by item_producto order by SUM(item_cantidad))
--Son 2 enfoques distintos pero resuelven lo mismo

/*11. Realizar una consulta que retorne el detalle de la familia, la cantidad diferentes de
productos vendidos y el monto de dichas ventas sin impuestos. Los datos se deberán
ordenar de mayor a menor, por la familia que más productos diferentes vendidos tenga,
solo se deberán mostrar las familias que tengan una venta superior a 20000 pesos para
el año 2012.*/
select fami_detalle, count(distinct prod_codigo) as 'cant prods vendidos', 
	   sum (item_precio * item_cantidad) as 'Total sin impuestos'
from Familia
join Producto on fami_id = prod_familia
join Item_Factura on prod_codigo = item_producto
join Factura on item_numero=fact_numero

WHERE prod_codigo IN (SELECT item_producto FROM Item_Factura GROUP BY item_producto) 
group by fami_detalle
having fami_detalle in (
	select fami_detalle from Familia
	join Producto on fami_id = prod_familia
	join Item_Factura on prod_codigo = item_producto
	join Factura on item_numero=fact_numero
	where year(fact_fecha) = 2012
 -- el where no va arriba porque el where condiciona TODO el query
	group by fami_detalle 
	--having ( sum(fact_total)>20000 ) 
	--Como la atomicidad de la query es por factura, poner el having le estaría sumando a cada factura la cantidad de rengloes que tiene
	having( sum (item_precio * item_cantidad)>20000) 
 )
order by 2 desc

/*12. Mostrar nombre de producto, cantidad de clientes distintos que lo compraron, importe
promedio pagado por el producto, cantidad de depósitos en los cuales hay stock del
producto y stock actual del producto en todos los depósitos. Se deberán mostrar
aquellos productos que hayan tenido operaciones en el año 2012 y los datos deberán
ordenarse de mayor a menor por monto vendido del producto.*/
select prod_detalle, count(distinct fact_cliente) as 'cantidad clientes',
	   avg(item_precio) as 'precio promedio',
	   -- el de abajo es un subselect porque si hago join depósito me cambia la atomicidad
	   (select count(distinct depo_codigo) from DEPOSITO join STOCK on depo_codigo = stoc_deposito where prod_codigo = stoc_producto ) as 'cant depos con stock', 
	   (select SUM(stoc_cantidad) from STOCK where stoc_producto=prod_codigo) as 'Stock total del producto'
from Producto
join Item_Factura on item_producto = prod_codigo
join Factura on fact_tipo+fact_sucursal+fact_numero=item_tipo+item_sucursal+item_numero 
where prod_codigo in 
	(select item_producto from Item_Factura 
	 join Factura 
	 on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
	 where year(fact_fecha) = 2012)
group by prod_detalle, prod_codigo
order by sum(item_precio) desc
/*13. Realizar una consulta que retorne para cada producto que posea composición: 
* nombre del producto, 
* precio del producto, 
* precio de la sumatoria de los precios por la cantidad de los productos que lo componen. 
Solo se deberán mostrar los productos que estén compuestos por más de 2 productos 
y deben ser ordenados de mayor a menor por cantidad de productos que lo componen.*/
select P1.prod_detalle, P1.prod_precio, 
	   sum(comp_cantidad * P2.prod_precio) as 'Precio combo' ,
	   count(distinct comp_componente) as 'Cant prods combo'

from Producto P1
join Composicion on comp_producto = prod_codigo
join producto P2 on P2.prod_codigo = comp_componente
-- estos join no cambian la atomicidad porque joineo por la primary key
group by P1.prod_detalle, P1.prod_precio
having (count(distinct comp_componente) >=2 )
order by count(distinct comp_componente) desc


--Joinea producto con producto  y no cambia la atomicidad si lo hace con la PK
--porque una vez joinea con comp_producto y la otra con comp_componente

/*14. 
Escriba una consulta que retorne una estadística de ventas por cliente. Los campos que debe retornar son:
- Código del cliente
- Cantidad de veces que compro en el último año
- Promedio por compra en el último año
- Cantidad de productos diferentes que compro en el último año
- Monto de la mayor compra que realizo en el último año
Se deberán retornar todos los clientes ordenados por la cantidad de veces que compro en el último año.
No se deberán visualizar NULLs en ninguna columna
*/
select  clie_codigo, -- una mazcla rara de Fede, enrique y yo¿¿
	    count(distinct fact_numero) as 'Cantidad de compras', 
		AVG(isnull(fact_total,0)) as 'Promedio de compras',
		(select COUNT(distinct item_producto) from Item_Factura join Factura on item_numero=fact_numero where fact_cliente=clie_codigo) as 'Cantidad prods distintos',
		max(isnull(fact_total,0)) as 'Monto mayor compra'
from Cliente
left join Factura on fact_cliente = clie_codigo
where year (fact_fecha) = (select max(year(fact_fecha)) from Factura)
	  or fact_fecha is null
group by clie_codigo
order by 2 desc
/*15) 
Escriba una consulta que retorne los pares de productos que hayan sido vendidos juntos
(en la misma factura) más de 500 veces. El resultado debe mostrar el código y
descripción de cada uno de los productos y la cantidad de veces que fueron vendidos
juntos. El resultado debe estar ordenado por la cantidad de veces que se vendieron
juntos dichos productos. Los distintos pares no deben retornarse más de una vez.
Ejemplo de lo que retornaría la consulta:
PROD1 DETALLE1 PROD2 DETALLE2 VECES
1731 MARLBORO KS 1 7 1 8 P H ILIPS MORRIS KS 5 0 7
1718 PHILIPS MORRIS KS 1 7 0 5 P H I L I P S MORRIS BOX 10 5 6 2
*/

select p1.prod_codigo, p1.prod_detalle, p2.prod_codigo, p2.prod_detalle, count(*) as 'Veces'
from  Item_Factura i1
join Producto p1 on p1.prod_codigo = i1.item_producto
join Item_Factura i2 on i1.item_producto != i2.item_producto
join Producto p2 on p2.prod_codigo = i2.item_producto
where (p1.prod_codigo>p2.prod_codigo) and i1.item_numero = i2.item_numero
group by p1.prod_codigo, p1.prod_detalle, p2.prod_codigo, p2.prod_detalle
having count(*)>500
order by 5
/*
16) 
Se pide una consulta SQL que retorne aquellos clientes cuyas compras ($) son inferiores a 1/3 del promedio de ventas ($) del producto que más se vendió en el 2012.
Además mostrar 
1. Nombre del Cliente
2. Cantidad de unidades totales vendidas en el 2012 para ese cliente. 
3. Código de producto que mayor venta tuvo en el 2012 (en caso de existir más de 1, mostrar solamente el de menor código) para ese cliente. 
Aclaraciones:
La composición es de 2 niveles, es decir, un producto compuesto solo se compone de productos no compuestos.
4. Los clientes deben ser ordenados por código de provincia ascendente. 
*/

select clie_razon_social as 'Nombre',
	   (select count(distinct item_cantidad) from Factura
		join Item_Factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
		where clie_codigo = fact_cliente and year(fact_fecha) = 2012
		)as 'Unidades totales 2012',
	    (select top 1(item_cantidad) 
		 from factura 
		 join Item_Factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
		 where year(fact_fecha)=2012 and clie_codigo = fact_cliente
		 order by item_cantidad desc
		 )as 'Producto con mas ventas en 2012 para el cliente'
from cliente
where (select sum(fact_total) as '$ Suma de todas las compras' 
	   from Factura 
	   where clie_codigo = fact_cliente 
	   group by fact_cliente) < 
	  ((select top 1 AVG(item_cantidad * item_precio) as 'promedio en $ del mas vendido en 2012'
		from Producto
		join Item_Factura on item_producto = prod_codigo
		join Factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
		where year(fact_fecha) = 2012
		group by prod_codigo
		order by 1 desc)/3)
group by  clie_razon_social, clie_domicilio, clie_codigo
order by clie_domicilio asc
--------------------------------------------------------------------------------------------------------------------------------------------
/* 17) Escriba una consulta que retorne una estadística de ventas por año y mes para cada producto.
La consulta debe retornar:
PERIODO: Año y mes de la estadística con el formato YYYYMM 
PROD: Código de producto 
DETALLE: Detalle del producto 
CANTIDAD_VENDIDA= Cantidad vendida del producto en el periodo 
VENTAS_AÑO_ANT= Cantidad vendida del producto en el mismo mes del periodo pero del año anterior
CANT_FACTURAS= Cantidad de facturas en las que se vendió el producto en el periodo
La consulta no puede mostrar NULL en ninguna de sus columnas y debe estar ordenada
por periodo y código de producto.
*/
select (CONCAT(year(f1.fact_fecha),'  ',month(f1.fact_fecha))) as 'PERIODO' ,
	   prod_codigo as 'CODIGO PROD',
	   prod_detalle as 'DETALLE',
	   sum(item_cantidad) as 'CANTIDAD VENDIDA',
	   isnull((select sum(item_cantidad) from Item_Factura join Factura f2 on f2.fact_tipo+f2.fact_sucursal+f2.fact_numero=item_tipo+item_sucursal+item_numero
	   where prod_codigo = item_producto and year(f2.fact_fecha)-1 = year(f1.fact_fecha) and MONTH(f2.fact_fecha)=MONTH(f1.fact_fecha)
	   ),0) as 'VENTAS AÑO ANT',
	   count(*)as 'CANTIDAD FACTURAS'
from Producto
join Item_Factura on item_producto = prod_codigo
join Factura f1 on f1.fact_tipo+f1.fact_sucursal+f1.fact_numero=item_tipo+item_sucursal+item_numero
GROUP BY YEAR(f1.fact_fecha), MONTH(f1.fact_fecha), prod_codigo, prod_detalle
order by YEAR(f1.fact_fecha), MONTH(f1.fact_fecha), prod_codigo

/* 18) Escriba una consulta que retorne una estadística de ventas para todos los rubros. 
La consulta debe retornar:
1. DETALLE_RUBRO: Detalle del rubro 
2. VENTAS: Suma de las ventas en $ de productos vendidos de dicho rubro  SUM(item_precio*item_cantidad)
3. PROD1: Código del producto más vendido de dicho rubro 
4. PROD2: Código del segundo producto más vendido de dicho rubro 
5. CLIENTE: Código del cliente que compro más productos del rubro (en los últimos 30 días - esto lo saco pq va a dar todo NULL)
6. La consulta no puede mostrar NULL en ninguna de sus columnas 
7. y debe estar ordenada por cantidad de productos diferentes vendidos del rubro. 
*/
select rubr_detalle as 'DETALLE_RUBRO',
	   ISNULL(SUM(item_precio * item_cantidad),0) 'VENTAS',
	   isnull((select top 1 (ps.prod_codigo) from Producto ps join Item_Factura on item_producto = ps.prod_codigo 
	    where rubr_id = ps.prod_rubro 
		group by ps.prod_codigo
		order by sum(item_cantidad*item_precio) desc),0)as 'PROD MAS VENDIDO',
		isnull((select top 1 (ps2.prod_codigo) from Producto ps2 join Item_Factura on item_producto = ps2.prod_codigo 
	    where rubr_id = ps2.prod_rubro and ps2.prod_codigo!=
		(select top 1 (ps3.prod_codigo) from Producto ps3 join Item_Factura on item_producto = ps3.prod_codigo 
	    where rubr_id = ps3.prod_rubro 
		group by ps3.prod_codigo
		order by sum(item_cantidad*item_precio) desc)  
		group by ps2.prod_codigo
		order by sum(item_cantidad*item_precio) desc),0)as '2° PROD MAS VENDIDO',
		isnull((select top 1 fact_cliente from Factura fc join Item_Factura ic
		 on fc.fact_tipo+fc.fact_sucursal+fc.fact_numero=ic.item_tipo+ic.item_sucursal+ic.item_numero
		 join Producto on prod_codigo=item_producto
		 where prod_rubro = rubr_id order by(item_cantidad) ),'-') as 'CLIENTE' 
from Rubro
left join producto on rubr_id = prod_rubro
left join Item_Factura on prod_codigo=item_producto
left join Factura ON fact_tipo+fact_sucursal+fact_numero=item_tipo+item_sucursal+item_numero
group by rubr_id, rubr_detalle
ORDER BY COUNT(distinct item_producto) DESC
/*
19)
En virtud de una recategorizacion de productos referida a la familia de los mismos se
solicita que desarrolle una consulta sql que retorne para todos los productos:
1. Codigo de producto 
2. Detalle del producto 
3. Codigo de la familia del producto 
4. Detalle de la familia actual del producto 

5. Codigo de la familia sugerido para el producto
6. Detalla de la familia sugerido para el producto
!!!!!!!! La familia sugerida para un producto es la que poseen la mayoria de los productos cuyo detalle coinciden en los primeros 5 caracteres.
8. En caso que 2 o mas familias pudieran ser sugeridas se debera seleccionar la de menor codigo. 
9. Solo se deben mostrar los productos para los cuales la familia actual sea diferente a la sugerida
10. Los resultados deben ser ordenados por detalle de producto de manera ascendente
*/
select  pp.prod_codigo as 'CODIGO PRODUCTO',
		pp.prod_detalle as 'DETALLE PRODUCTO',
		ff.fami_id as 'CODIGO FAMILIA ACTUAL',
		ff.fami_detalle as 'DETALLE FAMILIA ACTUAL',
		(select top 1 f.fami_detalle from familia f join Producto p on p.prod_familia=f.fami_id  
		 where LEFT(p.prod_detalle,5) = LEFT(pp.prod_detalle,5) 
		 group by f.fami_id, f.fami_detalle 
		 order by count(f.fami_id) desc) as 'DETALLE FAMILIA SUGERIDA', 
		(select top 1 f.fami_id from familia f join Producto p on p.prod_familia=f.fami_id  
		 where LEFT(p.prod_detalle,5) = LEFT(pp.prod_detalle,5) 
		 group by f.fami_id, f.fami_detalle 
		 order by count(f.fami_id) desc) as 'ID FAMILIA SUGERIDA'
from Producto pp
join Familia ff on pp.prod_familia=ff.fami_id
where fami_id != (select top 1 f.fami_id from familia f join Producto p on p.prod_familia=f.fami_id  
		 where LEFT(p.prod_detalle,5) = LEFT(pp.prod_detalle,5) 
		 group by f.fami_id, f.fami_detalle 
		 order by count(f.fami_id) desc)
group by fami_detalle, prod_codigo,prod_detalle, fami_id
order by 2 asc
-----------------------------------------------------------
SELECT	P1.prod_codigo'Prod Codigo', 
		P1.prod_detalle'Prod Detalle', 
		P1.prod_familia'Familia Codigo', 
		F1.fami_detalle'Familia Detalle',
		(SELECT TOP (1) F2.fami_id
		FROM Producto P2 JOIN Familia F2 ON P2.prod_familia=F2.fami_id 
		WHERE LEFT(P1.prod_detalle,5)=LEFT(P2.prod_detalle,5) 
		GROUP BY F2.fami_id
		ORDER BY COUNT(F2.fami_id) DESC, F2.fami_id ASC
		)'Familia Sugerida Codigo',
		(SELECT TOP (1) F2.fami_detalle
		FROM Producto P2 JOIN Familia F2 ON P2.prod_familia=F2.fami_id 
		WHERE LEFT(P1.prod_detalle,5)=LEFT(P2.prod_detalle,5) 
		GROUP BY F2.fami_id, F2.fami_detalle
		ORDER BY COUNT(F2.fami_id) DESC, F2.fami_id ASC
		)'Familia Sugerida Detalle'
FROM Producto P1 JOIN Familia F1 ON P1.prod_familia=F1.fami_id
-- el where es para que la familia sugerida sea distinta de la actual
WHERE F1.fami_id != (SELECT TOP (1) F2.fami_id 
		FROM Producto P2 JOIN Familia F2 ON P2.prod_familia=F2.fami_id 
		WHERE LEFT(P1.prod_detalle,5)=LEFT(P2.prod_detalle,5) 
		GROUP BY F2.fami_id
		ORDER BY COUNT(F2.fami_id) DESC, F2.fami_id ASC
		)
order by 4
/*
20) Escriba una consulta sql que retorne un ranking de los mejores 3 empleados del 2012
Se debera retornar 
1. legajo,  2. nombre y  3. apellido,  4. anio de ingreso,  5. puntaje 2011, 6. puntaje 2012. 
El puntaje de cada empleado se calculara de la siguiente manera: para los que
hayan vendido al menos 50 facturas el puntaje se calculara como la cantidad de facturas
que superen los 100 pesos que haya vendido en el año, 

para los que tengan menos de 50 facturas en el año el calculo del puntaje sera el 50% 
de cantidad de facturas realizadas por sus subordinados directos en dicho año.
*/
select top 3 empl_codigo as 'LEGAJO',
	   (rtrim(empl_nombre)+' '+rtrim(empl_apellido)) as 'Nombre empleado',
	   year(empl_ingreso) as 'AÑO INGRESO',
	   (select case
				   when count(*)>=50 then (select count(*) from Factura 
										   where fact_vendedor = empl_codigo and year(fact_fecha)=2011 and fact_total>100)
				   else 0.5*(select count(*) from factura join Empleado sub on fact_vendedor=sub.empl_codigo 
							 where sub.empl_jefe = empl_codigo)
			   end as puntaje
		FROM Factura WHERE empl_codigo=fact_vendedor AND year(fact_fecha)=2011)'Puntaje 2011',
		(select case
				   when count(*)>=50 then (select count(*) from Factura 
										   where fact_vendedor = empl_codigo and year(fact_fecha)=2012 and fact_total>100)
				   else 0.5*(select count(*) from factura join Empleado sub on fact_vendedor=sub.empl_codigo 
							 where sub.empl_jefe = empl_codigo)
			   end as puntaje
		FROM Factura WHERE empl_codigo=fact_vendedor AND year(fact_fecha)=2012)'Puntaje 2012'

from empleado 
order by 5 desc, 4 desc
/*21)
Escriba una consulta sql que retorne para todos los años, en los cuales se haya hecho al
menos una factura, la cantidad de clientes a los que se les facturo de manera incorrecta
al menos una factura y qué cantidad de facturas se realizaron de manera incorrecta. 

Se considera que una factura es incorrecta cuando la diferencia entre el total de la factura
menos el total de impuesto tiene una diferencia mayor a $ 1 respecto a la sumatoria de
los costos de cada uno de los items de dicha factura. Las columnas que se deben mostrar
son:
1. Año
2. Clientes a los que se les facturo mal en ese año
3. Facturas mal realizadas en ese año
*/
select  year(fact_fecha) as 'AÑO FACTURA',
 count(distinct fact_cliente) as 'Clientes mal facturados',
 count(*) as 'Facturas mal hechas'
from Factura
where fact_total - fact_total_impuestos - 
(select sum(item_precio*item_cantidad) from item_factura
 where fact_numero+fact_sucursal+fact_tipo = item_numero+item_sucursal+item_tipo)> 1
group by year(fact_fecha)
/* 22)
Escriba una consulta sql que retorne una estadistica de venta para todos los rubros por
trimestre contabilizando todos los años. Se mostraran como maximo 4 filas por rubro (1
por cada trimestre).
Se deben mostrar 4 columnas:
1. Detalle del rubro 
2. Numero de trimestre del año (1 a 4) 
3. Cantidad de facturas emitidas en el trimestre en las que se haya vendido al menos un producto del rubro 
4. Cantidad de productos diferentes del rubro vendidos en el trimestre 
5. El resultado debe ser ordenado alfabeticamente por el detalle del rubro y dentro de cada rubro primero el trimestre 
en el que mas facturas se emitieron. 
6. No se deberan mostrar aquellos rubros y trimestres para los cuales las facturas emitidas no superen las 100.
7. En ningun momento se tendran en cuenta los productos compuestos para esta estadistica 
*/
select  rubr_detalle as 'Detalle rubro',
		DATEPART(QUARTER, fact_fecha) as '# Trimestre',-- ni puta idea, se lo copie a federico :)
		count(distinct item_numero+item_sucursal+item_tipo)  as 'Facturas en el trimestre' ,
		count(distinct prod_codigo) as 'Cantidad productos distintos'
from Rubro
join Producto on prod_rubro=rubr_id
join Item_Factura on prod_codigo=item_producto
join Factura on fact_numero+fact_sucursal+fact_tipo = item_numero+item_sucursal+item_tipo
-- where para que los productos no estén en una composición 
where prod_codigo not in (select comp_producto from Composicion)
group by rubr_detalle, DATEPART(QUARTER, fact_fecha)
having count(distinct item_numero+item_sucursal+item_tipo) > 100
order by 1 asc , 3 desc
SELECT	rubr_detalle 'Detalle Rubro', 
		DATEPART(QUARTER, fact_fecha) 'Trimestre', 
		count(distinct fact_tipo+fact_sucursal+fact_numero) 'Cant Facts Emitidas', 
		count(distinct prod_codigo) 'Cant Prods Dif Vendidos' 
FROM Rubro 
JOIN Producto ON rubr_id=prod_rubro
JOIN Item_Factura ON prod_codigo=item_producto
JOIN Factura ON item_tipo+item_sucursal+item_numero=fact_tipo+fact_sucursal+fact_numero
WHERE prod_codigo NOT IN (SELECT comp_producto FROM Composicion)
GROUP BY rubr_detalle, DATEPART(QUARTER, fact_fecha)
HAVING count(distinct fact_tipo+fact_sucursal+fact_numero) > 100
ORDER BY 1, 3 DESC
/*
23)
Realizar una consulta SQL que para cada año muestre :
1. Año 
2. El producto con composición más vendido para ese año. 
3. Cantidad de productos que componen directamente al producto más vendido 
4. La cantidad de facturas en las cuales aparece ese producto. 
5. El código de cliente que más compro ese producto. 
6. El porcentaje que representa la venta de ese producto respecto al total de venta del año. 
7. El resultado deberá ser ordenado por el total vendido por año en forma descendente. 
*/
select YEAR(fact_fecha) as 'AÑO',
	   prod_codigo as 'Producto con composición + vendido',
	  (select count(distinct comp_componente) from Composicion where comp_producto=prod_codigo) as 'Cant componentes',
	   count (distinct fact_tipo+fact_sucursal+fact_numero) as 'Cantidad Facturas',
	   (select top 1 fact_cliente from Factura join Item_Factura on fact_tipo+fact_sucursal+fact_numero=item_tipo+item_sucursal+item_numero
	   where  item_producto = prod_codigo group by fact_cliente order by sum(item_cantidad) desc) as 'Cliente que mas compro',

	   sum(item_cantidad * item_precio) * 100 / (select sum(fact_total) from Factura  where year(fact_fecha) = year(F1.fact_fecha )) as 'Porcentaje'-- (venta del producto / venta total * 100) 
from Factura F1
join Item_Factura on item_tipo+item_sucursal+item_numero=F1.fact_tipo+F1.fact_sucursal+F1.fact_numero
join Producto on prod_codigo = item_producto
join Composicion on comp_producto = prod_codigo
-- Pongo en el where como condición que traiga al combo mas vendido de cada año porque lo pide para todas las columnas 
WHERE prod_codigo = (SELECT TOP (1) comp_producto
		FROM Composicion
		JOIN Item_Factura ON comp_producto=item_producto
		JOIN Factura F2 ON F2.fact_tipo+F2.fact_sucursal+F2.fact_numero=item_tipo+item_sucursal+item_numero 
		WHERE year(F2.fact_fecha)= year(F1.fact_fecha)
		GROUP BY comp_producto
		ORDER BY (SELECT COUNT(*) FROM Item_Factura WHERE item_producto=comp_producto) DESC)
group by YEAR(fact_fecha), prod_codigo
order by (select sum(fact_total) from Factura  where year(fact_fecha) = year(F1.fact_fecha )) desc
/* 24) Escriba una consulta que considerando solamente las facturas correspondientes a los dos vendedores con mayores comisiones, 
retorne los productos con composición facturados al menos en cinco facturas.
La consulta debe retornar las siguientes columnas:
1. Código de Producto 
2. Nombre del Producto 
3. Unidades facturadas 
4. El resultado deberá ser ordenado por las unidades facturadas descendente.*/
select prod_codigo as 'Codigo producto',
	   prod_detalle as 'Detalle producto',
	   sum(item_cantidad) as 'Unidades facturadas'
from Factura
join Item_Factura on fact_tipo+fact_sucursal+fact_numero=item_tipo+item_sucursal+item_numero 
join Producto on item_producto = prod_codigo
where fact_vendedor in (select top (2) empl_codigo from Empleado order by empl_comision desc) 
	  and prod_codigo in (select comp_producto from Composicion)
group by prod_codigo, prod_detalle
having count ( item_producto )>=5
order by 3 desc
/*
25) 
Realizar una consulta SQL que para cada año y familia muestre :
a. Año
b. El código de la familia más vendida en ese año. (En pesos? o en cantidad de produtos?? ) (YO le mande en plata)
c. Cantidad de Rubros que componen esa familia.
d. Cantidad de productos que componen directamente al producto más vendido de esa familia.
e. La cantidad de facturas en las cuales aparecen productos pertenecientes a esa familia.
f. El código de cliente que más compró productos de esa familia.
g. El porcentaje que representa la venta de esa familia respecto al total de venta del año.
El resultado deberá ser ordenado por el total vendido por año y familia en forma
descendente.

*/
select YEAR(fact_fecha) as 'AÑO',
	   
	   P.prod_familia  as 'Familia mas vendida',
	   
	   (select count (distinct prod_rubro)from Producto join Rubro on rubr_id=prod_rubro 
	    where prod_familia = P.prod_familia ) as 'Cantidad rubros en Familia',
		
		(select count(distinct comp_componente) from Composicion where comp_producto = 
		(select top 1 prod_codigo from Producto join Item_Factura on item_producto=prod_codigo 
		where prod_familia = P.prod_familia order by (item_cantidad) desc)) as 'Cantidad elementos composicion',
		
		count(distinct fact_tipo+fact_sucursal+fact_numero) as 'Cant Facturas con familia',
		
		(select top 1 fact_cliente from Factura 
		join Item_Factura on fact_tipo+fact_sucursal+fact_numero=item_tipo+item_sucursal+item_numero 
		join Producto on item_producto = prod_codigo
		where year(fact_fecha) = year(F.fact_Fecha) and P.prod_familia=prod_familia
		group by fact_cliente
		order by sum(item_cantidad*item_precio) desc ) as 'Cliente que mas compro a la familia',
		
		--El porcentaje que representa la venta de esa familia respecto al total de venta del año.
		-- o sea, 100*ventas familia / ventas totales
		100*(sum(item_cantidad * item_precio))/
		(select sum(item_cantidad * item_precio) from Item_Factura 
		 join Factura on fact_tipo+fact_sucursal+fact_numero=item_tipo+item_sucursal+item_numero
		 where year(fact_fecha) = year(F.fact_fecha) 
		 ) as '% ventas de la familia'
		
from Producto P
join Item_Factura on item_producto = P.prod_codigo
join Factura F on F.fact_tipo+F.fact_sucursal+F.fact_numero=item_tipo+item_sucursal+item_numero 
where (select top 1 fami_id as 'FAMILIA MAS VENDIDAAAAA' from Familia 
	   join Producto on prod_familia=fami_id
	   join Item_Factura on item_producto = prod_codigo
	   join Factura on fact_tipo+fact_sucursal+fact_numero=item_tipo+item_sucursal+item_numero 
	   group by fami_id
	   order by sum(item_cantidad*item_precio) desc
	   ) = prod_familia
group by YEAR(fact_fecha), P.prod_familia
order by 1 desc
/*
26)
Escriba una consulta sql que retorne un ranking de empleados devolviendo las siguientes columnas:
BUENO acá el resuelto pone que todo es relativo al 2012 así que por las dudas pra que de lo mismo lo voy a hacer así tambien y fue
1. Empleado  2. Depósitos que tiene a cargo (Cantidad) 3. Monto total facturado en el año corriente  4. Codigo de Cliente al que mas le vendió  5. Producto más vendido 
6. Porcentaje de la venta de ese empleado sobre el total vendido ese año. 
Los datos deberan ser ordenados por venta del empleado de mayor a menor.*/
 --(rtrim(empl_nombre)+' '+rtrim(empl_apellido)) as 'Nombre empleado',
select	empl_codigo as 'Empleado',
		(select count(*) from DEPOSITO where depo_encargado=empl_codigo) as 'Depositos a cargo',
		--isnull((select sum(fact_total) from Factura f where year(f.fact_fecha )=2012 and fact_vendedor=empl_codigo),0) as 'Total facturado 2012'
		-- esto que está comentado sería si no hiciera todo relativo al 2012 y tengo que hacer subselect porque esta columna SI tiene aclarado el año
		ISNULL(SUM(fact_total),0) as 'Total 2012',
		isnull((select top (1) f.fact_cliente from Factura f where fact_vendedor=empl_codigo and year(f.fact_fecha) = YEAR(ff.fact_fecha)
		 group by f.fact_cliente order by count(*) desc),'---') as 'Clie que mas compro',
		isnull((select top (1) item_producto from Item_Factura join factura f on f.fact_tipo+f.fact_sucursal+f.fact_numero=item_tipo+item_sucursal+item_numero
		where fact_vendedor=empl_codigo and year(ff.fact_fecha) = YEAR(f.fact_fecha)
		group by item_producto
		order by sum(item_cantidad)DESC),'-') as 'Producto mas vendido',
		100*isnull((sum(fact_total))/(select SUM(fact_total) from Factura f where year(f.fact_fecha) = year(ff.fact_fecha)),0) as 'Porcentaje sobre ventas anuales'
from Empleado
left join Factura ff on ff.fact_vendedor=empl_codigo and (YEAR(ff.fact_fecha)=2012)
group by empl_codigo, year(ff.fact_fecha)
order by 3 desc
/* 27)
Escriba una consulta sql que retorne una estadística basada en la facturacion por año y
envase devolviendo las siguientes columnas:
1. Año 2. Codigo de envase 3. Detalle del envase 4. Cantidad de productos que tienen ese envase	
5. Cantidad de productos facturados de ese envase  6. Producto mas vendido de ese envase (entiendo que en ese periodo) 
7. Monto total de venta de ese envase en ese año 8. Porcentaje de la venta de ese envase respecto al total vendido de ese año
*/
select year(fact_fecha) as 'AÑO',
	   enva_detalle as 'DETALLE ENVASE',
	   enva_codigo as 'CODIGO ENVASE',
	   (SELECT count(*) FROM Producto WHERE prod_envase=enva_codigo) as 'CANT PRODS x ENVASE',
	  --(select count(distinct prod_codigo) from Producto where prod_envase=enva_codigo group by prod_envase  ) as 'CANT PRODS con ENVASE' ,
	  --2 formas de hacer la misma columna
	   sum(item_cantidad) as 'PRODUCTOS FACTURADOS x ENVASE',
	   (select top (1) item_producto from Item_Factura 
	    join Factura f on  item_tipo+item_sucursal+item_numero=f.fact_tipo+f.fact_sucursal+f.fact_numero
		join Producto on prod_codigo = item_producto
		where prod_envase=enva_codigo and YEAR(f.fact_fecha) = YEAR(ff.fact_fecha)
		group by item_producto
		order by sum(item_cantidad) 
		) as 'Prod más vendido x año x envase',
		sum(item_precio*item_cantidad) as '$ total ventas x envase x año',
		100*sum(item_precio*item_cantidad)/(select sum(item_precio*item_cantidad) from Item_Factura 
	    join Factura f on  item_tipo+item_sucursal+item_numero=f.fact_tipo+f.fact_sucursal+f.fact_numero
		join Producto on prod_codigo = item_producto
		where YEAR(f.fact_fecha) = YEAR(ff.fact_fecha)) as '% de ventas x env x año'

from Envases
join Producto on prod_envase = enva_codigo
join Item_Factura on item_producto = prod_codigo
join Factura ff on item_tipo+item_sucursal+item_numero=ff.fact_tipo+ff.fact_sucursal+ff.fact_numero
group by year(fact_fecha),enva_codigo,enva_detalle
order by 1,3


select * from Producto
/*28) 
. Escriba una consulta sql que retorne una estadística por Año y Vendedor que retorne las
siguientes columnas:
Año. Codigo de Vendedor Detalle del Vendedor 
Cantidad de facturas que realizó en ese año Cantidad de clientes a los cuales les vendió en ese año.
Cantidad de productos facturados con composición en ese año Cantidad de productos facturados sin composicion en ese año.
Monto total vendido por ese vendedor en ese año

Los datos deberan ser ordenados por año y dentro del año 
por el vendedor que haya vendido mas productos diferentes de mayor a menor.a de la empresa, o sea, el que en monto haya vendido más.
*/
select year(fact_fecha) as 'AÑO',
	   empl_codigo as 'CODIGO VENDEDOR',
	   CONCAT(RTRIM(empl_nombre),' ',rtrim(empl_apellido)) as 'Detalle Vendedor',
	   count(*) as 'Facturas x vend x año',
	   count (distinct fact_cliente) as 'Cant Clientes',
	   isnull((select count(*) from Composicion 
	    join Producto on comp_producto = prod_codigo 
		join Item_Factura on item_producto = prod_codigo 
		join Factura ff on ff.fact_tipo+ff.fact_sucursal+ff.fact_numero = item_tipo+item_sucursal+item_numero
		where YEAR(f.fact_fecha)=YEAR(ff.fact_fecha) and f.fact_vendedor = ff.fact_vendedor
		group by ff.fact_vendedor),0) as 'Combos facturados x año x vend',
		isnull((select count(*) from Producto  
		join Item_Factura on item_producto = prod_codigo 
		join Factura ff on ff.fact_tipo+ff.fact_sucursal+ff.fact_numero = item_tipo+item_sucursal+item_numero
		where YEAR(f.fact_fecha)=YEAR(ff.fact_fecha) and f.fact_vendedor = ff.fact_vendedor
		and item_producto not in (select prod_codigo from Producto join Composicion
								  on comp_producto=prod_codigo)
		group by ff.fact_vendedor),0) as 'Prods NO combos x año x vend',
		sum (fact_total) as '$ total x año x vend'
from Factura f
join Empleado on empl_codigo = fact_vendedor
group by year(fact_fecha), empl_codigo, empl_apellido, empl_nombre, fact_vendedor
--order by 1 asc, 8 desc
order by 8

/*
29) 
Se solicita que realice una estadística de venta por producto para el año 2011, solo para 
los productos que pertenezcan a las familias que tengan más de 20 productos asignados 
a ellas, la cual deberá devolver las siguientes columnas: 
a. Código de producto 
b. Descripción del producto 
c. Cantidad vendida 
d. Cantidad de facturas en la que esta ese producto 
e. Monto total facturado de ese producto 

Solo se deberá mostrar un producto por fila en función a los considerandos establecidos 
antes.  El resultado deberá ser ordenado por el la cantidad vendida de mayor a menor.
*/
select prod_codigo as 'Codigo producto',
	   prod_detalle as 'Desc producto' ,
	   sum(item_cantidad) as 'Cantidad vendida',
	   count(*) as 'Cantidad facturas',
	   sum(item_cantidad*item_precio) as 'Total facturado'
from Factura
join Item_Factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
join Producto p on prod_codigo=item_producto
where year(fact_fecha) = 2011 and p.prod_familia in 
								  (select prod_familia from Producto group by prod_familia having count(*) > 20)
group by prod_codigo, prod_detalle
order by 1


/*
32) Se desea conocer las familias que sus productos se facturaron juntos en las mismas facturas. 
Para ello se solicita que escriba una consulta sql que retorne los pares de 
familias que tienen productos que se facturaron juntos.  Para ellos deberá devolver las 
siguientes columnas: 
Código de familia, Detalle de familia, Código de familia, Detalle de familia  
5. Cantidad de facturas 
6. Total vendido 
Los datos deberan ser ordenados por Total vendido y solo se deben mostrar las familias 
que se vendieron juntas más de 10 veces. 
*/
select  f1.fami_id as 'Codigo F1', f1.fami_detalle as 'Detalle F1' ,
	   f2.fami_id as 'Codigo F2', f2.fami_detalle as 'Detalle F2' ,
	   COUNT(distinct i1.item_tipo+i1.item_sucursal+i1.item_numero) 'Cant facturas',
	   sum(i1.item_cantidad*i1.item_precio+i2.item_cantidad*i2.item_precio)  as 'Total vendido'
from Familia f1
join Producto p1 on p1.prod_familia = f1.fami_id
join Item_Factura i1 on p1.prod_codigo= i1.item_producto
join Item_Factura i2 on i1.item_tipo+i1.item_sucursal+i1.item_numero=i2.item_tipo+i2.item_sucursal+i2.item_numero 
-- que sean items de la misma factura
join Producto p2 on p2.prod_codigo= i2.item_producto
join Familia f2 on p2.prod_familia = f2.fami_id
where (f1.fami_id<f2.fami_id) 
group by f1.fami_id, f2.fami_id, f1.fami_detalle , f2.fami_detalle
having (count(distinct i1.item_tipo+i1.item_sucursal+i1.item_numero)>10) -- que se vendieron juntas mas de 10 veces
order by 6
/*
33) Se requiere obtener una estadística de venta de productos que sean componentes. 
Para ello se solicita que realiza la siguiente consulta que retorne la venta de los 
componentes del producto más vendido del año 2012.  Se deberá mostrar: 

Precio promedio facturado de ese producto. 
Total facturado para ese producto 

El resultado deberá ser ordenado por el total vendido por producto para el año 2012. 
*/
select prod_codigo as 'Codigo Prod', prod_detalle as 'Nombre prod',
	   isnull((select SUM(item_cantidad) from Item_Factura join Producto p on p.prod_codigo=item_producto and p.prod_codigo = comp_componente),0) as 'Cant unidades vendidas',
	   (select count(distinct f.fact_numero+f.fact_sucursal+f.fact_tipo) from Item_Factura join Producto p on p.prod_codigo=item_producto 
	   join factura f on f.fact_numero+f.fact_sucursal+f.fact_tipo = item_numero+item_sucursal+item_tipo
	   and p.prod_codigo = comp_componente
	   ) as 'Cant facturas',
	   isnull((select AVG(item_precio * item_cantidad) from Item_Factura 
	   join Producto p on p.prod_codigo=item_producto and p.prod_codigo = comp_componente),0) as 'Precio promedio x factura',
	   isnull((select sum(item_precio * item_cantidad) from Item_Factura 
	   join Producto p on p.prod_codigo=item_producto and p.prod_codigo = comp_componente),0) as 'Total facturado'
from Producto
join Composicion on prod_codigo=comp_componente
join Item_Factura on comp_producto=item_producto
join Factura on item_numero+item_sucursal+item_tipo=fact_numero+fact_sucursal+fact_tipo
where comp_producto = (select top (1) prod_codigo from Producto
					 join Item_Factura on prod_codigo = item_producto 
					 join Factura on item_numero+item_sucursal+item_tipo=fact_numero+fact_sucursal+fact_tipo
					 where prod_codigo in (select comp_producto from Composicion) and YEAR(fact_fecha)=2012  
					 group by prod_codigo
					 order by sum(item_cantidad) desc) --esto me da el combo
group by prod_codigo, prod_detalle , comp_componente
order by 6