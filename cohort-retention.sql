WITH enrolled_students AS (SELECT DISTINCT
                                a.sfrstcr_term_code,
                                a.sfrstcr_term_code + 100 AS return_term,
                                a.sfrstcr_pidm
                           FROM sfrstcr a
                          WHERE a.sfrstcr_camp_code <> 'XXX'
                            AND a.sfrstcr_rsts_code IN (SELECT b.stvrsts_code
                                                           FROM stvrsts b
                                                         WHERE b.stvrsts_incl_sect_enrl = 'Y') )

SELECT c.sgrchrt_term_code_eff AS cohort_term,
       cc.stvchrt_desc AS cohort_desc,
       a.sfrstcr_term_code AS Start_Term,
       a.return_term,
       a.sfrstcr_pidm,
       h.spbpers_sex,
       COALESCE( dsc.f_get_race_ethn(a.sfrstcr_pidm),
          dsc.f_get_race_ethn(a.sfrstcr_pidm,1),
          'Unknown' ) AS race_ethn1,
       CASE WHEN b.sfrstcr_pidm IS NOT NULL THEN 'Y'
            ELSE 'N'
             END AS retention_ind,
       e.stvcoll_desc,
       f.stvmajr_desc,
       d.sgbstdn_degc_code_1,
       ROUND((SUM(g.shrtgpa_quality_points)/NULLIF(SUM(g.shrtgpa_gpa_hours),0)),3) AS dsu_gpa
     FROM (SELECT aa.*
             FROM enrolled_students aa
            WHERE aa.sfrstcr_term_code > '201140'
              AND SUBSTR(aa.sfrstcr_term_code,5,2) = '40') a
LEFT JOIN enrolled_students b
       ON a.sfrstcr_pidm = b.sfrstcr_pidm
      AND a.return_term = b.sfrstcr_term_code
LEFT JOIN sgrchrt c
       ON a.sfrstcr_pidm = c.sgrchrt_pidm
      AND c.sgrchrt_chrt_code NOT LIKE 'S%' -- Errant student success codes
      AND c.sgrchrt_chrt_code NOT LIKE '0%' -- Errant fall 2005 new UG code
LEFT JOIN stvchrt cc
       ON c.sgrchrt_chrt_code = cc.stvchrt_code
LEFT JOIN sgbstdn d
       ON a.sfrstcr_pidm = d.sgbstdn_pidm
LEFT JOIN stvcoll e
       ON d.sgbstdn_coll_code_1 = e.stvcoll_code
LEFT JOIN stvmajr f
       ON d.sgbstdn_majr_code_1 = f.stvmajr_code
LEFT JOIN shrtgpa g
       ON a.sfrstcr_pidm = g.shrtgpa_pidm
      AND g.shrtgpa_levl_code = 'UG'
      AND g.shrtgpa_gpa_type_ind = 'I'
      AND g.shrtgpa_term_code != '000000'
      AND g.shrtgpa_term_code <= a.sfrstcr_term_code
LEFT JOIN spbpers h
       ON a.sfrstcr_pidm = h.spbpers_pidm
    WHERE d.sgbstdn_term_code_eff = (SELECT MAX(dd.sgbstdn_term_code_eff)
                                       FROM sgbstdn dd
                                      WHERE d.sgbstdn_pidm = dd.sgbstdn_pidm
                                        AND dd.sgbstdn_term_code_eff <= a.sfrstcr_term_code)
  GROUP BY c.sgrchrt_term_code_eff, cc.stvchrt_desc, a.sfrstcr_term_code, a.return_term, a.sfrstcr_pidm, h.spbpers_sex, COALESCE( dsc.f_get_race_ethn(a.sfrstcr_pidm),
          dsc.f_get_race_ethn(a.sfrstcr_pidm,1),
          'Unknown' ), CASE WHEN b.sfrstcr_pidm IS NOT NULL THEN 'Y'
            ELSE 'N'
             END, e.stvcoll_desc, f.stvmajr_desc, d.sgbstdn_degc_code_1
ORDER BY a.sfrstcr_pidm
