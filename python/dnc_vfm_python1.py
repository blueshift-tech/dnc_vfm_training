# Import packages
import pandas as pd
import geocoder
import pandas_gbq

# Read in the polling place file and select only the top 15 rows (so it doesn't take forever to run)
data = pd.read_csv('pollplace.csv').head(15)

# Reformat column names

# Create an empty list that we can populate with our new column names
cols = []

# Loop through each column in our dataset
for col in data.columns:
    # Create a new string for the column name that is all lowercase and replaces spaces with underscores
    new_col = col.lower().replace(' ','_')

    # Append the new column name to the end of the list
        # Note, the new column name has to be in square brackets [] so add it to the existing list
    cols = cols + [new_col]

# Set the column names of our dataset to the new ones
data.columns = cols

# Create a new column in our dataset for the county_fips and set all of the values to 201 (the FIPS code for Harris County)
data['county_fips'] = '201'

# Create a new column in our dataset with the geocode information for the address
    # Note that we're slicing the last 4 digits off of the end of the addresses to convert zip+4 to zip5
data['geo'] = data['address'].apply(lambda x:geocoder.osm(x[:-4]))

# Extract the geocode parts from the new geocode column
data['address'] = data['geo'].apply(lambda x:str(x.housenumber)+' '+str(x.street))
data['zip'] = data['geo'].apply(lambda x:x.postal)
data['city'] = data['geo'].apply(lambda x:x.city)
data['state'] = data['geo'].apply(lambda x:x.state)
data['lat'] = data['geo'].apply(lambda x:x.lat)
data['lon'] = data['geo'].apply(lambda x:x.lng)

# Upload the final dataset to Phoenix using the default application credentials set on your command line
pandas_gbq.to_gbq(data,'sbx_kahlea.harris_cty_polling_locations',project_id='demstraining',if_exists="replace")

# Export the final dataset to a csv in your project folder
data.to_csv('cleaned_polling_locations.csv')
