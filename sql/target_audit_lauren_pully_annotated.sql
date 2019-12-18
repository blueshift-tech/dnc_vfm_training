/**
Pull survey responses and scores for a model validation report

IMPORTANT: Find and replace the dataset names to match for your state
IMPORTANT: Add the list of master survey question IDs (in quotes) at line 33

*/

SELECT
            p.myv_van_id                                                        -- Unique VAN ID for each person
            , sq.survey_question_name                                           -- VAN name of survey questions
            , sq.master_survey_question_id                                      -- VAN master survey question ID
            , sr.survey_response_name                                           -- VAN name of survey response
            , c.committee_name                                                  -- VAN Committee responsible for the contact
            , m_date.max_date                                                   -- Date of most recent response
            , rv.contact_type_id                                                -- VAN type of contact (phone, walk, text, etc)
            , s.* EXCEPT(myv_van_id)                                            -- All available modeled scores
FROM `democrats.analytics_tx.person` p
LEFT JOIN (
  /*
    Subquery to pull the date of most recent survey response

    Subqueries need to be wrapped in parentheses and given an alias (m_date in this case)
  */

      SELECT
        myv_van_id                                                              -- Unique VAN ID to join to the other tables later
        , MAX(datetime_canvassed) as max_date                                   -- The maximum (most recent) timestamp for each person
      FROM demstxsp.vansync.contacts_survey_responses_myv                       -- Table with all survey responses from voter contact in VAN
      LEFT JOIN demstxsp.vansync.survey_responses sr                            -- JOINing in the survey response names
        ON sr.survey_response_id = r.survey_response_id
      LEFT JOIN demstxsp.vansync.survey_questions sq                            -- JOINING in the survey question names
        ON sq.survey_question_id = r.survey_question_id
      WHERE sr.master_survey_response_id IS NOT NULL AND                        -- Only people with a master survey response
            sq.master_survey_question_id IS NOT NULL AND                        -- Only people with a master survey question
            sq.master_survey_question_id IN (                                   -- Only people in the list of master survey questions (limited to support questions only)

              -- Comma separated list of

            )
      GROUP BY myv_van_id
    ) AS m_date

    /*
      CAST the myv_van_id columns to STRINGs so they will match

      SQL returns an error if you try to JOIN on columns with different types

      Because these are IDs, we want them as strings to preserve any leading zeroes
    */

    ON CAST(p.myv_van_id AS STRING) = CAST(m_date.myv_van_id AS STRING)         -- JOINing the subquery to analytics.person

LEFT JOIN demstxsp.vansync.contacts_survey_responses_myv rv
  ON rv.myv_van_id = m_date.myv_van_id                                          -- JOINing all survey responses on BOTH VAN ID and the date so it only returns the most recent response (based on our table above)
    AND rv.datetime_canvassed = m_date.max_date
LEFT JOIN demstxsp.vansync.survey_responses sr                                  -- JOINing in the survey response names
  ON sr.survey_response_id = rv.survey_response_id
LEFT JOIN demstxsp.vansync.survey_questions sq                                  -- JOINing in the survey question names
  ON sq.survey_question_id = rv.survey_question_id
  /*
    The USING keyword JOINs two tables with the exact same column name

    This is the same as writing
      ON c.committee_id = rv.committee_id
  */
LEFT JOIN `vansync.committees` c USING(committee_id)                            -- JOINing in VAN commitees
LEFT JOIN `demstxsp.commons.tx_all_scores_QA` s                                 -- JOINing in all predictive models for comparison
  ON p.myv_van_id = s.myv_van_id
