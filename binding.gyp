{
  "targets": [
    {
      "target_name": "osxsleep",
      "sources": [ "sleep.mm" ],
      "cflags": ["-Wall", "-std=c++11","-framework IOKit","-framework CoreFoundation"],
      "conditions": [ 
        [ "OS=='mac'", { 
            "xcode_settings": { 
                "OTHER_CPLUSPLUSFLAGS" : ["-std=c++11","-stdlib=libc++"], 
                "OTHER_LDFLAGS": ["-stdlib=libc++"], 
                "MACOSX_DEPLOYMENT_TARGET": "10.7" } 
            }
        ] 
      ] 
    }
  ]
}
