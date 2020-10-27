WITH enrolled_students AS (
    SELECT DISTINCT
           a.sfrstcr_term_code AS enrolled_term,
           a.sfrstcr_pidm AS enrolled_pidm,
           'Y' AS enrolled_ind
      FROM sfrstcr a
     WHERE a.sfrstcr_camp_code <> 'XXX'
       ANd a.sfrstcr_rsts_code IN (
           SELECT b.stvrsts_code
             FROM stvrsts b
            WHERE b.stvrsts_incl_sect_enrl = 'Y') )

    SELECT a.sgrchrt_term_code_eff AS s_cohort_entry,
           a.sgrchrt_chrt_code AS s_cohort,
           a.sgrchrt_pidm AS s_pidm,
           c.spbpers_sex AS sex,
           COALESCE( dsc.f_get_race_ethn(a.sgrchrt_pidm),
                     dsc.f_get_race_ethn(a.sgrchrt_pidm,1),
                     'Unknown' ) AS race_ethnicity,
           b.enrolled_term,
           'Year '||( (b.enrolled_term - a.sgrchrt_term_code_eff) * .01) AS relative_period,
           ROUND((d.total_quality_points / NULLIF(d.total_gpa_hours,0)),3) AS dsu_gpa,
           f.stvcoll_desc AS primary_college,
           g.stvmajr_desc AS primary_major
      FROM sgrchrt a
 LEFT JOIN enrolled_students b
        ON a.sgrchrt_pidm = b.enrolled_pidm
       AND a.sgrchrt_term_code_eff <= b.enrolled_term
 LEFT JOIN spbpers c
        ON a.sgrchrt_pidm = c.spbpers_pidm
 LEFT JOIN (SELECT dd.shrtgpa_pidm,
                   dd.shrtgpa_term_code,
                   SUM(dd.shrtgpa_quality_points) OVER (PARTITION BY dd.shrtgpa_pidm ORDER BY dd.shrtgpa_term_code) AS total_quality_points,
                   SUM(dd.shrtgpa_gpa_hours) OVER (PARTITION BY dd.shrtgpa_pidm ORDER BY dd.shrtgpa_term_code) AS total_gpa_hours
              FROM shrtgpa dd
             WHERE dd.shrtgpa_levl_code = 'UG'
               AND dd.shrtgpa_gpa_type_ind = 'I'
               AND dd.shrtgpa_term_code != '000000') d
        ON a.sgrchrt_pidm = d.shrtgpa_pidm
       AND b.enrolled_term = d.shrtgpa_term_code
 LEFT JOIN sgbstdn e
        ON a.sgrchrt_pidm = e.sgbstdn_pidm
 LEFT JOIN stvcoll f
        ON e.sgbstdn_coll_code_1 = f.stvcoll_code
 LEFT JOIN stvmajr g
        ON e.sgbstdn_majr_code_1 = g.stvmajr_code
     WHERE a.sgrchrt_term_code_eff > 201140
       AND a.sgrchrt_chrt_code NOT LIKE 'S%'        -- Errant student success codes
       AND a.sgrchrt_chrt_code NOT LIKE '0%'        -- Errant fall 2005 codes
       AND SUBSTR(b.enrolled_term, 5, 2) = '40'     -- Limit results to fall terms.
       AND SUBSTR(a.sgrchrt_term_code_eff, 5, 2) = '40'
       AND e.sgbstdn_term_code_eff = (SELECT MAX(ee.sgbstdn_term_code_eff)
                                        FROM sgbstdn ee
                                       WHERE e.sgbstdn_pidm = ee.sgbstdn_pidm
                                         AND ee.sgbstdn_term_code_eff <= e.enrolled_term)
