WITH Median2023 AS (
    SELECT 
        City,
        Neighbourhood,
        `Property Type`,
        ROUND(AVG(`Closed Price`/`Above Grade Sq Ft`), 0) AS `2023 Median`
    FROM (
        SELECT 
            City,
            Neighbourhood,
            `Property Type`,
            LEFT(`Close Date`, 4) AS Close_Year,
            `Closed Price`,
            `Above Grade Sq Ft`,
            ROW_NUMBER() OVER (PARTITION BY City, Neighbourhood, `Property Type`, LEFT(`Close Date`, 4) ORDER BY `Closed Price`) AS rn,
            COUNT(*) OVER (PARTITION BY City, Neighbourhood, `Property Type`, LEFT(`Close Date`, 4)) AS cnt
        FROM solds
    ) AS dd
    WHERE rn IN (FLOOR((cnt + 1) / 2), FLOOR((cnt + 2) / 2)) AND Close_Year = '2023'
    GROUP BY City, Neighbourhood, `Property Type`
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
),
Count2023 AS (
    SELECT 
        City,
        Neighbourhood,
        `Property Type`,
        COUNT(`Closed Price`) AS `2023 Count`
    FROM solds
    WHERE LEFT(`Close Date`, 4) = '2023'
    GROUP BY City, Neighbourhood, `Property Type`
),
Median2022 AS (
    SELECT 
        City,
        Neighbourhood,
        `Property Type`,
        ROUND(AVG(`Closed Price`/`Above Grade Sq Ft`), 0) AS `2022 Median`,
        COUNT(`Closed Price`) AS `2022 Count`
    FROM (
        SELECT 
            City,
            Neighbourhood,
            `Property Type`,
            LEFT(`Close Date`, 4) AS Close_Year,
            `Closed Price`, 
            `Above Grade Sq Ft`,
            ROW_NUMBER() OVER (PARTITION BY City, Neighbourhood, `Property Type`, LEFT(`Close Date`, 4) ORDER BY `Closed Price`) AS rn,
            COUNT(*) OVER (PARTITION BY City, Neighbourhood, `Property Type`, LEFT(`Close Date`, 4)) AS cnt
        FROM solds
    ) AS dd
    WHERE rn IN (FLOOR((cnt + 1) / 2), FLOOR((cnt + 2) / 2)) AND Close_Year = '2022'
    GROUP BY City, Neighbourhood, `Property Type`
),
MDOM22 AS (
    SELECT 
        City,
        Neighbourhood,
        `Property Type`,
        ROUND(AVG(DOM), 0) AS MedianDOM22
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
    WHERE rn IN (FLOOR((cnt + 1) / 2), FLOOR((cnt + 2) / 2)) AND Close_Year = '2022'
    GROUP BY City, Neighbourhood, `Property Type`
),
Count2022 AS (
    SELECT 
        City,
        Neighbourhood,
        `Property Type`,
        COUNT(`Closed Price`) AS `2022 Count`
    FROM solds
    WHERE LEFT(`Close Date`, 4) = '2022'
    GROUP BY City, Neighbourhood, `Property Type`
)

SELECT 
    s.City,
    s.Neighbourhood,
    s.`Property Type`,
    m.`2023 Median`,
    o.MedianDOM23,
    c.`2023 Count`,
    n.`2022 Median`,
    p.MedianDOM22,
    b.`2022 Count`,
    ROUND(m.`2023 Median`/n.`2022 Median`, 2) AS `Y/Y 23/22`
FROM solds s
LEFT JOIN Median2023 m ON s.City = m.City AND s.Neighbourhood = m.Neighbourhood AND s.`Property Type` = m.`Property Type`
LEFT JOIN MDOM23 o ON s.City = o.City AND s.Neighbourhood = o.Neighbourhood AND s.`Property Type` = o.`Property Type`
LEFT JOIN Count2023 c ON s.City = c.City AND s.Neighbourhood = c.Neighbourhood AND s.`Property Type` = c.`Property Type`
LEFT JOIN Median2022 n ON s.City = n.City AND s.Neighbourhood = n.Neighbourhood AND s.`Property Type` = n.`Property Type`
LEFT JOIN MDOM22 p ON s.City = p.City AND s.Neighbourhood = p.Neighbourhood AND s.`Property Type` = p.`Property Type`
LEFT JOIN Count2022 b ON s.City = b.City AND s.Neighbourhood = b.Neighbourhood AND s.`Property Type` = b.`Property Type`
WHERE s.Neighbourhood != 'N/A' AND m.`2023 Median` IS NOT NULL AND n.`2022 Median` IS NOT NULL AND c.`2023 Count` > 1 AND b.`2022 Count` > 1
GROUP BY s.City, s.Neighbourhood, s.`Property Type`, m.`2023 Median`, o.MedianDOM23, c.`2023 Count`, n.`2022 Median`, p.MedianDOM22, b.`2022 Count`;