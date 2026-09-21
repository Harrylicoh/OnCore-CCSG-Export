SELECT
	sp.protocol_no 
	, sp.protocol_id
	, pl.description library
	, CASE sp.investigator_initiated
	   WHEN 'Y' THEN 'Yes'
	   WHEN 'N' THEN 'No' END iit
	, dt4.description dt4_type
	, COALESCE(spon_type_o.description, pcl_spon.spon_types) eval_spon_types
    , pcl_spon.spon_ids p_spon_ids
FROM oncore.smrs_protocol sp
LEFT JOIN oncore.pf_code dt4
	ON sp.summary4_report_type = dt4.code_id
	   AND dt4.active_flag = 'Y'
LEFT JOIN oncore.pf_library pl
    ON sp.library_id = pl.library_id 
        AND pl.active_flag = 'Y'
LEFT JOIN oncore.pf_code spon_type_o
    ON sp.sponsor_type_override = spon_type_o.code_id
LEFT JOIN (
    SELECT
        protocol_id
        , LISTAGG(ss.sponsor, ',') WITHIN GROUP (ORDER BY sps.protocol_id) spon_ids
        , LISTAGG(spon_type.description, ',') WITHIN GROUP (ORDER BY sps.protocol_id) spon_types
    FROM oncore.smrs_pcl_sponsor sps 
    LEFT JOIN oncore.smrs_sponsor ss
        ON sps.sponsor = ss.sponsor
    LEFT JOIN oncore.pf_code spon_type
        ON ss.sponsor_type = spon_type.code_id 
    WHERE
        1 = 1
        AND principal_sponsor = 'Y'
    GROUP BY
        sps.protocol_id 
) pcl_spon
    ON sp.protocol_id = pcl_spon.protocol_id