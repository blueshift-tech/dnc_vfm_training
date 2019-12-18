/**
Pull total phone attempts and contacts for organizers by day

IMPORTANT: Find and replace the dataset names to match for your state
IMPORTANT: Change the organizer usernmae conventions in lines 21 and 22

*/

/*
  WITH statements are incredibly useful for creating a temporary table that is only used during your query

  WITH queries need to be labeled (using AS) and wrapped in parentheses

  You can include multiple WITH queries, just use a comma after the close parenthesis and label the next query (see note below)

*/

WITH lu AS (                                                                    -- Label WITH query

      SELECT
        DISTINCT                                                                -- Use DISTINCT to only return one row per organizer
        us.first_name
        , us.last_name
        , us.user_id                                                            -- We'll need the user_id field to JOIN to the other vansyn tables later
        , us.username
        , CONCAT(us.last_name,', ',us.first_name) AS van_name                   -- CONCAT combines multiple strings; we'll use it to create both the name as it appears in VAN and a more standardized name
        , CONCAT(us.first_name,' ',us.last_name) AS name

      FROM demsflsp.vansync.users us

      /*
        This part only works if your VAN usernames are standardized in a way to make it easy to find organizers

        If not, you'll have to list our organizer usernames manually using IN ('','')
      */

      WHERE (LOWER(us.username) LIKE '%fdpcp%'                                  -- Use LOWER and LIKE to only return usernames that match the standard for organizers
      OR LOWER(us.username) LIKE '%fdporg%')

    )

    /*
      Here we could add more WITH queries

      We don't need to repeat the word WITH, just add a comma and a temporary table name with AS:

      MAke sure there isn't a comma after the last parenthesis though!

      WITH table1 AS (

      ),
      table2 AS (
      ),
      table3 AS (
      )
    */

  SELECT
    CAST(datetime_created AS DATE) AS date_created                              -- CAST the datetime AS DATE to remove the time so we can GROUP BY the date
    , lu.name                                                                   -- The concatenated name from our WITH query
    /*
      SUM(CASE WHEN) is a useful syntax for counting specific values in a column

      The CASE WHEN statement returns a 1 when a column meets some criteria and a 0 for anytihng else

      Then when the column is SUMmed, the values we want are counted as 1s and the values we don't are counted as 0s
    */
    , SUM(CASE WHEN result_id IS NOT NULL THEN 1 ELSE 0 END) AS attempts        -- Use SUM(CASE WHEN) to count rows with a result_id (where there was a phone attempt)
    , SUM(CASE WHEN result_id = '14' THEN 1 ELSE 0 END) AS contacts             -- Use SUM(CASE WHEN) to count rows where the result_id is 14 (where the result was 'Contacted')
  FROM lu
  INNER JOIN demsflsp.vansync.contacts_contacts_myv calls                       -- JOIN contacts_contacts_myv and alias it as calls
    ON (lu.user_id = calls.created_by_user_id)                                  -- JOIN using the created_by_user_id column on the calls table to the organizer user id from our WITH statement above
  WHERE contact_type_id = '1'                                                   -- Use WHERE to filter to only attempts where the contact type was 'Phone'
    AND datetime_created >= '2019-09-01'                                        -- Also filter to rows where the contacted by date is since 9/1/2019
  GROUP BY date_created, name                                                   -- GROUP BY our date and name columns
