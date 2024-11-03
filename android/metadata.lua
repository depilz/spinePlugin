local metadata =
{
   plugin =
   {
      format = 'jar',
      manifest = 
      {
         permissions =
         {
         },
         usesPermissions =
         {
         },
         applicationChildElements =
         {
          -- [[
          --     <meta-data
          --         android:name="onesignal_app_id"
          --         tools:node="remove" />
          --     <meta-data
          --         android:name="onesignal_google_project_number"
          --         tools:node="remove" />
          -- ]]
         },
      },
   },
   coronaManifest = {
    dependencies = {
      -- ["shared.firebase.messaging"] = "com.coronalabs",
   },
  },
}

return metadata