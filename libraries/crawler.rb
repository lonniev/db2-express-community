class Chef::Recipe::Crawler
  class << self
    def load_dependencies
      require 'mechanize'
    end

    def download_links( archiveSet )

      load_dependencies

      agent = Mechanize.new { |agent|
        agent.user_agent_alias = 'Windows Chrome'
        agent.follow_meta_refresh = true
        agent.pluggable_parser.default = Mechanize::Download
      }

      # map each zipname into a IBM-token-credentialed URL to download the named file and return that mapped array of links
      discovered = archiveSet.map { |entry|

        page = agent.get( entry[:url] )

        # the client will be challenged to login with a Contact Form
        form = page.form_with( 'contact' ) unless !page

        if ( form )

          field = form.field_with( "user.email" )
          field.value = entry[:userEmail] unless !field

          field = form.field_with( "user.firstName" )
          field.value = entry[:firstName] unless !field

          field = form.field_with( "user.lastName" )
          field.value = entry[:lastName] unless !field

          field = form.field_with( "user.company" )
          field.value = entry[:company] unless !field

          field = form.field_with( "user.countryCode" )
          field.value = entry[:countryCode] unless !field

          field = form.checkbox_with( "licenseAccepted" )
          field.check unless !field

          page = form.submit

          form = page.form_with( "downloadForm" ) unless !page

          if ( form )

            # we have picked up any session cookies and URL parameters needed for granted access

            # we switch from the picking page to the downloading page and ask for http downloading
            download_url = "#{entry[:url].gsub( /pick.do/, 'download.do' )}&dlmethod=http"

            page = agent.get( download_url )

            # interactively, the download would begin automatically. Here, though, we
            # only want to return the matching Mechanize Link instance
            link = page.link_with( :href => Regexp.new( entry[:remoteArchive] ) ) unless !page
          end
        end
      }.flatten.compact.select{ |l| l.respond_to?( :uri ) }

      # at least return an empty collection
      # (any non-empty collection returned will also only have elements that respond_to uri() )
      Array.new().concat( discovered )
    end
  end
end
