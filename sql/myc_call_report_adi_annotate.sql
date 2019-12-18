/**
Pull total My Campaign calls by organizer turf

Assign volunteers to organizer turf by Activity Region if exists, if not assign by My Voters precinct

IMPORTANT: Find and replace the dataset names to match for your state
IMPORTANT: Replace the committee_id at lines 35, 38, and 40

*/

SELECT

  /*
    COALESCE returns the first non-null value of its arguments

    In the cases below, the Activity Region will be returned first, but if it is NULL the region will be assigned by My Voters precinct
  */

  COALESCE(ar.region_name,t.region_name) AS region,                             -- VAN Region Name
  COALESCE(ar.fo_name,t.fo_name) AS organizer,                                  -- VAN Organizer Turf
  COUNT(DISTINCT contacts_contact_id) AS calls                                  -- Distinct number of calls made
  COUNT(                                                                        -- Distinct number of contacts
        CASE
          WHEN result_id = '14'                                                 -- CASE WHEN counts contacts_contacts_id only when the result is "Canvassed" (result_id 14)
          THEN contacts_contact_id
        END
      ) AS contacts
FROM
  demstxsp.vansync.contacts_contacts_myc cmc                                    -- Start with contacts_contacts_myc (a record of every attempt)
LEFT JOIN
  demstxsp.vansync.person_records_myc prc                                       -- JOIN in person_records_myc for the VAN precinct information
  ON prc.myc_van_id = cmc.myc_van_id
LEFT JOIN demstxsp.vansync.activity_regions ar                                  -- JOIN in activity_regions by myc_van_id
    ON ar.myc_van_id = cmc.myc_van_id
    AND ar.committee_id = '61652'                                               -- Use a single side of a JOIN ON to filter to only one committee (like a WHERE)
LEFT JOIN demstxsp.vansync.turf t                                               -- JOIN precinct_id turf assignments
    ON t.van_precinct_id = prc.van_precinct_id
    AND t.committee_id = '61652'                                                -- Use a single side of a JOIN ON to filter to only one committee (like a WHERE)
WHERE
  cmc.committee_id = '61652'                                                    -- Filter to only contacts in a committee
  AND t.region_name IS NOT NULL                                                 -- Filter to only records that are assigned to a region
  AND t.fo_name IS NOT NULL                                                     -- Filter to only records that are assigned to an FO turf
GROUP BY
  1,2
ORDER BY
  1,2
