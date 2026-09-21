WITH pcl_scope AS (
	SELECT
		pcl.protocol_id
		, pcl.library_id
		, pcl.summary4_report_type
		, pcl.protocol_no
		, pcl.nci_id
		, pcl.nct_id
		, pcl.investigator_initiated
		, pl.description library
		, dt4_type.description dt4
	FROM oncore.smrs_protocol pcl
	LEFT JOIN oncore.pf_library pl
		ON pcl.library_id = pl.library_id
	LEFT JOIN oncore.pf_code dt4_type
		ON pcl.summary4_report_type = DT4_TYPE.code_id
	WHERE
		1 = 1
		{protocol_criteria}
), po_id AS (
	SELECT
		o.organization_id
		, o.name enrollment_institution
		, oi.identifier po_id
	FROM ONCORE.ORGANIZATION o 
	LEFT JOIN ONCORE.ORGANIZATION_IDENTIFIER oi
		ON o.organization_id = oi.organization_id
			AND oi.organization_id_type_id = 2 -- PO_ID
)
SELECT
	spcs.protocol_subject_id
	, spcs.protocol_id
	, spcs.subject_no
	, ps.protocol_no
	, ps.nci_id
	, ps.nct_id
	, spcs.sequence_number
	, ss.zip
	, c.code country_code
	, ss.birth_date
	, bs.name gender
	, race.description race
	, CASE WHEN eth.description = 'Non-Hispanic' THEN 'Not Hispanic or Latino' 
		ELSE eth.description END ethnicity
	, spcs.on_studydate
	, po_id.enrollment_institution
	, po_id.po_id
	, icd.code icd_code
FROM oncore.smrs_pcl_cent_subject spcs
LEFT JOIN oncore.smrs_subject ss
	ON spcs.subject_no = ss.subject_no
LEFT JOIN oncore.smrs_subject_race ssr
	ON ss.subject_no = ssr.subject_no
LEFT JOIN oncore.pf_code race
	ON ssr.race = race.code_id
LEFT JOIN oncore.pf_code eth
	ON ss.ethnicity = eth.code_id
LEFT JOIN ONCORE.COUNTRY c 
	ON ss.country = c.country_id	
LEFT JOIN oncore.biological_sex bs
	ON ss.biological_sex_id = bs.biological_sex_id
LEFT JOIN oncore.pf_code icd
	ON spcs.disease_site = icd.code_id
LEFT JOIN po_id
	ON spcs.organization_id = po_id.organization_id
INNER JOIN pcl_scope ps
	ON spcs.protocol_id = ps.protocol_id
WHERE
	1 = 1
	AND spcs.on_studydate IS NOT NULL