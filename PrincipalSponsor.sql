SELECT
	sq.*
FROM (
	SELECT
		sps.sponsor
		, ss.sponsor_name name
		, COUNT(sps.protocol_id) cnt
	FROM oncore.smrs_pcl_sponsor sps
	LEFT JOIN oncore.smrs_sponsor ss
		ON sps.sponsor = ss.sponsor
	WHERE
		1 = 1
		AND sps.principal_sponsor = 'Y'
	GROUP BY
		sps.sponsor
		, ss.sponsor_name
	ORDER BY
		cnt DESC
) sq
WHERE
	1 = 1
	AND rownum = 1