WITH Per AS (
    SELECT  
        City,
        Neighbourhood,
        `Property Type`, 
        ROUND(AVG(`Closed Price`/`Above Grade Sq Ft`), 0) AS PSqFt, 
        ROUND(AVG(`Closed Price`/(`Beds Total` + 1.0)), 0) AS PBeds, 
        ROUND(AVG(`Closed Price`/(`Baths Full` + (`Baths Half`/2.0))), 0) AS PBaths, 
        ROUND(AVG(`Closed Price`/(`Garage #` + 1.0)), 0) AS PGar,
        ROUND(AVG(`Closed Price`/Acres), 0) AS PAcres 
    FROM solds
    WHERE Neighbourhood != "N/A"
    GROUP BY City, Neighbourhood, `Property Type`
),

AVG_Payments AS (
    SELECT
        `Property Type`,
        ROUND(AVG(
            CASE
                WHEN `Property Tax` != 0 AND `Property Tax` != ' ' AND `Property Tax` < 100000 AND HOA < 10000
                THEN ((`Closed Price`/1000)*4.2)/12 + HOA + (`Property Tax`/12)
                ELSE NULL
            END
        ), 0) AS AVG_Payments
    FROM solds
    GROUP BY `Property Type`
),
MDOM23 AS (
    SELECT 
        City,
        Neighbourhood,
        `Property Type`,
        ROUND(AVG(DOM), 0) AS MedianDOM23
    FROM (
        SELECT 
            City,
            Neighbourhood,
            `Property Type`,
            LEFT(`Close Date`, 4) AS Close_Year,
            DOM, 
            ROW_NUMBER() OVER (PARTITION BY City, Neighbourhood, `Property Type`, LEFT(`Close Date`, 4) ORDER BY DOM) AS rn,
            COUNT(*) OVER (PARTITION BY City, Neighbourhood, `Property Type`, LEFT(`Close Date`, 4)) AS cnt
        FROM solds
    ) AS dd
    WHERE rn IN (FLOOR((cnt + 1) / 2), FLOOR((cnt + 2) / 2)) AND Close_Year = '2023'
    GROUP BY City, Neighbourhood, `Property Type`
)

SELECT
    DISTINCT avgs.`MLS #`,
    avgs.`List Price`,
    -- These have to be divided by property type vvv
    avgs.Base_Payments/ap.AVG_Payments Payments,
    g.city, 
    g.neighbourhood, 
    g.`Property Type`, 
    D23.MedianDOM23,
    avgs.rsqft, 
    avgs.rbeds, 
    avgs.rbaths, 
    avgs.rgar, 
    COALESCE(avgs.racres, 1) AS RAcres, 
    g.avg_income,
    ROUND((avgs.rsqft + avgs.rbeds + avgs.rbaths + avgs.rgar + COALESCE(avgs.racres, 1)) / 5, 2) AS AverageOrder,
    ROUND((avgs.rsqft + avgs.rbeds + avgs.rbaths + avgs.rgar + COALESCE(avgs.racres, 1) + avgs.Base_Payments/ap.AVG_Payments) / 6, 2) AS AverageOrder_Payments
FROM (
    SELECT
        l.`MLS #`,
        l.`List Price`,
        l.City,
        l.Neighbourhood,
        l.`Property Type`,
        ROUND(((l.`List Price`/1000)*4.2)/12+l.HOA+(l.`Property Tax`/12),0) AS Base_Payments,
        ROUND((l.`List Price`/l.`Above Grade Sq Ft`) / a.PSqFt, 2) AS RSqFt,
        ROUND((l.`List Price`/(l.`Beds Total` + 1)) / a.PBeds, 2) AS RBeds,
        ROUND((l.`List Price`/(l.`Baths Full` + (l.`Baths Half`/2))) / a.PBaths, 2) AS RBaths,
        ROUND((l.`List Price`/(l.`Garage #` + 1)) / a.PGar, 2) AS RGar,
        ROUND((l.`List Price`/l.Acres) / a.PAcres, 2) AS RAcres
    FROM listings l
    LEFT JOIN Per a
    ON l.City = a.City AND l.Neighbourhood = a.Neighbourhood AND l.`Property Type` = a.`Property Type`
    WHERE l.Neighbourhood != "N/A"
) avgs
LEFT JOIN (
    SELECT  
        cr.City, 
        cr.Neighbourhood, 
        cr.`Property Type`, 
        ROUND(AVG(a.Income) * 1000, 0) AS Avg_Income
    FROM (
        SELECT DISTINCT s.`MLS #`, 
            s.City, 
            s.Neighbourhood, 
            s.`Property Type`, 
            s.`Parcel Number`, 
            s.`Zip Code`, 
            c.`Carrier Routes`, 
            CONCAT(0,s.`Zip Code`,"-",c.`Carrier Routes`) AS `Zip & Route`
        FROM carrier c
        LEFT JOIN solds s
        ON c.`Parcel #` = s.`Parcel Number`
        WHERE s.`Parcel Number` IS NOT NULL AND TRIM(c.`Carrier Routes`) <> ''
    ) cr
    LEFT JOIN `all_income` a
    ON cr.`Zip & Route` = a.`Carrier Route`
    GROUP BY cr.city, cr.neighbourhood, cr.`Property Type`
) g
ON avgs.city = g.city AND avgs.neighbourhood = g.neighbourhood AND avgs.`Property Type` = g.`Property Type`
LEFT JOIN AVG_Payments ap ON avgs.`Property Type` = ap.`Property Type`
LEFT JOIN MDOM23 D23 ON g.city = D23.city AND g.neighbourhood = D23.neighbourhood AND g.`Property Type` = D23.`Property Type`
WHERE (COALESCE(avgs.racres, 1) < 1.33) 
AND avgs.rsqft < 1.33 
AND avgs.rbeds < 1.33 
AND avgs.rbaths < 1.33
AND avgs.rgar < 1.33 
AND avgs.Base_Payments/ap.AVG_Payments < 1.33
AND g.Avg_Income IS NOT NULL 
AND g.Avg_Income > 89000
AND avgs.`List Price` < 800000
ORDER BY AverageOrder DESC;
