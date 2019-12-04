import pandas as pd
import geocoder
import pandas_gbq
import re

data = pd.read_csv('pollplace.csv').head(15)

cols = []

for col in data.columns:
    new_col = col.lower().replace(' ','_')
    cols = cols + [new_col]

data.columns = cols

data['county_fips'] = '201'

data['address'].apply(lambda x:print(geocoder.osm(re.sub(' \S+$','',x))))

data['geo'] = data['address'].apply(lambda x:geocoder.osm(re.sub(' \S+$','',x)))

data['address'] = data['geo'].apply(lambda x:str(x.housenumber)+' '+str(x.street))
data['city'] = data['geo'].apply(lambda x:x.city)
data['state'] = data['geo'].apply(lambda x:x.state)
data['zip'] = data['geo'].apply(lambda x:x.postal)
data['lat'] = data['geo'].apply(lambda x:x.lat)
data['lon'] = data['geo'].apply(lambda x:x.lng)

print(data)

# pandas_gbq.to_gbq(data,'sbx_kahlea.harris_cty_polling_locations',project_id='demstraining',if_exists="replace")
