WITH pcl_data AS ( 
	SELECT  
		pcl.protocol_id 
		, pcl.protocol_no 
		, pcl.nci_id 
		, pcl.nct_id 
		, pcl.investigator_initiated 
		, pcl.status 
		, dt4.description dt4_report_type 
		, s.code scope_code 
		, s.description scope 
		, pcl.multi_site
	FROM
		oncore.smrs_protocol pcl 
	LEFT JOIN oncore.pf_code dt4 
		ON pcl.summary4_report_type = dt4.code_id 
	LEFT JOIN oncore.pf_code s 
		ON pcl.scope = s.code_id 
	WHERE 
		1 = 1
		{protocol_criteria}
), sub_data AS ( 
	SELECT 
		sps.protocol_id 
		, ss.subject_mrn 
		, sps.sequence_number 
		, ss.zip 
		, ss.birth_date 
		-- , ss.gender 
		, ss.BIOLOGICAL_SEX_ID 
		-- , ssr.race 
		, r.description race 
		-- , ss.ethnicity 
		, eth.description ethnicity 
		, sps.on_studydate 
		, po.organization_id 
		, po.name enrollment_institution 
		, ds.description disease_site_desc 
		, ds.code disease_site_code
		, po.po_id
		, row_number() OVER (PARTITION BY sps.protocol_subject_id ORDER BY ssr.race) race_num 
	FROM
		oncore.smrs_pcl_cent_subject sps 
	JOIN oncore.smrs_subject ss
		ON sps.subject_no = ss.subject_no 
			AND sps.on_studydate IS NOT NULL 
	LEFT JOIN oncore.smrs_subject_race ssr
		ON ss.subject_no = ssr.subject_no
	LEFT JOIN coh_ccc cc 
		ON sps.organization_id = cc.organization_id
	LEFT JOIN (
		SELECT
			o.organization_id
			, o.name
			, oi.identifier po_id
		FROM oncore.organization o
		LEFT JOIN oncore.organization_identifier oi
			ON o.organization_id = oi.organization_id
				AND oi.organization_id_type_id = (
				SELECT organization_id_type_id
				FROM oncore.organization_id_type
				WHERE
					1 = 1
					AND LOWER(name) LIKE '%po%'
				)
		) po
		ON sps.organization_id = po.organization_id
	LEFT JOIN oncore.pf_code ds 
		ON sps.disease_site = ds.code_id 
	LEFT JOIN oncore.pf_code eth 
		ON ss.ethnicity = eth.code_id 
	LEFT JOIN oncore.pf_code r 
		ON ssr.race = r.code_id 
	LEFT JOIN oncore.country c 
		ON ss.country = c.country_id 
), pcl_sub_cutoffs AS ( 
	SELECT 
		protocol_id 
		, MIN(on_studydate) earliest_accrual 
		, MAX(on_studydate) latest_accrual 
	FROM oncore.smrs_pcl_cent_subject 
	WHERE
		1 = 1
		AND on_studydate IS NOT NULL 
		AND protocol_id IN (SELECT DISTINCT protocol_id FROM pcl_data) 
	GROUP BY 
		protocol_id 
), date_range(cutoff_date) AS ( 
	SELECT 
		TRUNC(sysdate, 'MONTH') 
		+ INTERVAL '1' MONTH 
		- INTERVAL '1' DAY cutoff_date 
	FROM DUAL 
	UNION ALL 
	SELECT 
		(cutoff_date 
		+ INTERVAL '1' DAY 
		- INTERVAL '1' MONTH) 
		- INTERVAL '1' DAY 
	FROM date_range 
	WHERE
		1 = 1
		AND cutoff_date > DATE '1900-01-01' 
), calculated_accruals AS ( 
	SELECT 
		cutoff.protocol_id 
		, date_range.cutoff_date
		, sub_data.enrollment_institution
		, sub_data.po_id
		, COUNT(DISTINCT subject_mrn) total_accruals 
	FROM pcl_sub_cutoffs cutoff 
	INNER JOIN date_range 
		ON cutoff_date BETWEEN earliest_accrual AND TRUNC(latest_accrual, 'month') + INTERVAL '1' MONTH 
	INNER JOIN sub_data 
		ON sub_data.on_studydate BETWEEN cutoff.earliest_accrual AND date_range.cutoff_date 
			AND cutoff.protocol_id = sub_data.protocol_id 
	GROUP BY 
		cutoff.protocol_id
		, date_range.cutoff_date 
		, sub_data.enrollment_institution
		, sub_data.po_id
)
SELECT
	pcl.protocol_id
	, pcl.protocol_no 
	, ca.cutoff_date
	, ca.enrollment_institution
	, ca.po_id
	, ca.total_accruals 
	, pcl.nci_id
	, pcl.nct_id
FROM pcl_data pcl 
INNER JOIN calculated_accruals ca 
	ON pcl.protocol_id = ca.protocol_id 
WHERE
	1 = 1
	AND nci_id IS NOT NULL
ORDER BY 
	protocol_no
	, cutoff_date