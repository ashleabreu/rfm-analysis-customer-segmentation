/*
Análisis RFM
Autora: Ashley Abreu Vargas

Objetivo:
Segmentar a los clientes según Recency, Frequency y Monetary para identificar clientes de alto valor, leales y en riesgo.

Herramientas: 
- SQL
*/

-- Cálculo de RFM:
-- Este script crea una tabla temporal con el cálculo de Recency, Frequency y Monetary para luego poder hacer el análisis.

CREATE TEMPORARY TABLE RFM_base AS (
SELECT CustomerID,
		-- RECENCY 
        DATEDIFF(MAX(invoicedate), MIN(invoicedate)) as Recency_days, -- dias de diferencia entre la primera y la ultima compra del cliente
        -- FREQUENCY
        COUNT(DISTINCT invoiceno) as Frequency, -- cuantas compras distintas hizo el cliente
        -- MONETARY
        SUM(quantity * Unitprice) as Monetary -- total_price en la tabla 
FROM online_retail
WHERE Customerid IS NOT NULL
GROUP BY CustomerID); 

-- RFM Análisis:
-- Este script asigna scores usando NTILE y segmenta clientes mediante CASE WHEN.

SELECT a.CustomerID,
		a.recency_days,
        a.frequency,
        a.monetary,
		a.R_score,
        a.F_score,
        a.M_score,
        CONCAT(a.R_score, a.F_score, a.M_score) as RFM_score,
        
				CASE
					WHEN a.R_score >= 4 AND a.F_score >= 4 AND a.M_score >= 4 THEN 'Champions'
                    WHEN a.F_score >= 4 AND a.M_score >= 3 THEN 'Loyal Customers'
                    WHEN a.R_score >= 4 AND a.F_score >= 2 THEN 'Potencial Loyalist'
                    WHEN a.R_score <= 2 AND a.F_score >= 3 THEN 'At Risk'
                    WHEN a.R_score = 1 AND a.F_score = 1 THEN 'Lost Customers'
                    ELSE 'Others'
				END AS Segment
                    
FROM
(SELECT CustomerID,
		Recency_days,
        frequency,
        Monetary,
        NTILE(5) OVER (ORDER BY recency_days DESC) as r_score,
        NTILE(5) OVER (ORDER BY Frequency ASC) as F_score,
        NTILE(5) OVER (ORDER BY Monetary ASC) as M_score
FROM RFM_base
WHERE NOT CustomerID = 0) as a;
