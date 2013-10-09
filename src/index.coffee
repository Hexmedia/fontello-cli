fs = require 'fs'
needle = require 'needle'
{print} = require 'util'
path = require 'path'
unzip = require 'unzip'

fontello =

  install: (options) ->

    # Begin the download
    #
    host = 'http://fontello.com'

    data =
      config:
        file: options.config
        content_type: 'application/json'

    needle.post host, data, { multipart: true }, (error, response, body) ->
      throw error if error
      sessionId = body

      if response.statusCode is 200
        zipFile = needle.get("#{host}/#{sessionId}/get", (error, response, body) ->
          throw error if error
        )

        # If css and font directories were provided, extract the contents of
        # the download to those directories. If not, extract the zip file as normal.
        #
        if options.css and options.font
          zipFile
            .pipe(unzip.Parse())
            .on('entry', ((entry) ->
              {path:pathName, type} = entry

              if type is 'File'
                dirName = path.dirname(pathName).match(/\/([^\/]*)$/)?[1]
                fileName = path.basename pathName

                switch dirName
                  when 'css'
                    cssPath = path.join options.css, fileName
                    entry.pipe(fs.createWriteStream(cssPath))
                  when 'font'
                    fontPath = path.join options.font, fileName
                    entry.pipe(fs.createWriteStream(fontPath))
                  else
                    entry.autodrain()
            ))
            .on('finish', (->
              print 'Install complete.\n'.green
            ))

        else
          zipFile
            .pipe(unzip.Extract({ path: '.' }))
            .on('finish', (->
              print 'Install complete.\n'.green
            ))

module.exports = fontello
