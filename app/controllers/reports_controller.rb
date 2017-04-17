class ReportsController < ApplicationController

  def demographics
    @data = Hash.new
    #@accounts_data = Hash.new
    @scope = params[:scope]
    @filter = params[:filter]
    @id = params[:id]

    case @scope
    when "network"
      if @filter
        if @filter == "network"
          @filtered = Network.includes(:sites).find(@id)
          networks = [@filtered]
        else
          @error = "When scoped by network you can only filter by network."
          return
        end
      else
        networks = Network.includes(:sites).all
      end
      populateByScoped(networks)
    when "site"
      if @filter
        case @filter
        when "network"
          sites = Site.includes(:networks).where(:networks => {:id => @id})
          @filtered = Network.find(@id)
        when "site"
          @filtered = Site.find(@id)
          sites = [@filtered]
        else
          @error = "When scoped by site you can only filter by network and site."
          return
        end
      else
        sites = Site.all()
      end
      populateByScoped(sites)
    when "group"
      if @filter
        case @filter
        when "network"
          groups = Group.includes(site: :networks).where(:networks => {:id => @id})
          @filtered = Network.find(@id)
        when "site"
          #Post.where(status: 'published', user: User.where(admin: true)).includes(:user)
          groups = Group.includes(:site).where(site: @id)
          #groups = Group.includes(:site).where(:site => {:id => @id})
          @filtered = Site.find(@id)
          #return
        when "group"
          @filtered = Group.find(@id)
          groups = [@filtered]
        else
          @error = "When scoped by gropu you can only filter by network, site and group."
          return
        end
        populateByScoped(groups)
      end
    end
  end

  def projects
    @breakdown = params[:breakdown]
    @scope = params[:scope]
    @filter = params[:filter]
    @id = params[:id]
    @projects = Project.all
    @sites = Site.includes(:networks).all
    @evidence = Evidence.includes(:group, :project, :collaborations).all
    @groups = Group.includes(:site).all

    case @scope
    when "network", "site"
      group_s = Hash.new

      case @scope
      when "network"

      when "site"
        for group in @groups do
          #puts group.name
          if group.site
            include = true
            case @filter
            when "network"
              @filtered = Network.find(@id)
              include = false
              for network in group.site.networks do
                if network.id == @id.to_i
                  include = true
                end
              end
            when "site"
              @filtered = Network.find(@id)
              
            end
            if include
              group_s[group.id] = group.site.id
            end
          end
        end

        projects_data = Hash.new
        @project_titles = Hash.new
        @site_names = Hash.new

        for project in @projects do
          @project_titles[project.id] = project.title
        end

        for site in @sites do
          include = true
          if @filter == "network"
            include = false
            for network in site.networks do
              if network.id == @id.to_i
                include = true
              end
            end
          end
          if include
            @site_names[site.id] = site.name
            projects_data[site.id] = Hash.new
            for project in @projects do
              projects_data[site.id][project.id] = Hash.new
              project_data = projects_data[site.id][project.id]
              project_data['submitted'] = 0
              project_data['saved'] = 0
              project_data['collaborations'] = 0
            end
          end
        end

        for record in @evidence do
          if record.status == "submitted" or "saved"
            if group_s[record.group_id]
              projects_data[group_s[record.group_id]][record.project_id][record.status] += 1
              if record.status == "submitted"
                projects_data[group_s[record.group_id]][record.project_id]["collaborations"] += 1
                for collaborator in record.collaborations do
                  projects_data[group_s[record.group_id]][record.project_id]["collaborations"] += 1
                end
              end
            else
              puts "Record"
              puts record.id
              puts "does not have a valid site.\n"
            end
          else
            puts "Record"
            puts record.id.to_i
            puts "is not saved or submitted.\n"
          end
        end
      end
    when "group"
      @error = "Report scoped by group not set up yet."
      return
    end
    @data = projects_data
  end

  def ethnicity
    if params[:breakdown] == "platform"
      if params[:gender]
        gender = params[:gender]
        selected_users = User.includes(:profile).where("profiles.gender" => gender)
      else
        selected_users = User.all
        gender = "None Selected"
      end
      ethnicities = []
      for i in 0..9 do
        ethnicities[i] = [];
        ethnicities[i][0] = 0;
      end
      count = 0
      for user in selected_users do
        puts count
        profile = Profile.find_by(id: user.id)
        if profile
          puts profile.ethnicity_id
          ethnicity_id = profile.ethnicity_id.to_i
          ethnicities[ethnicity_id][0] += 1;
          count += 1
        end
      end

      for i in 0..9 do
        ethnicities[i][1] = ((ethnicities[i][0]/count.to_f) * 100).round(2)
      end

      puts "Ethnicities"
      puts ethnicities

      @ethnicities = ethnicities
      @gender = gender
    end
  end

  private

    def countAccount(account, s_hash)
      year = Time.new.year
      s_hash["Accounts"] += 1
      case account.role.name
      when "educator"
        s_hash["Educators"] += 1
      when "student"
        s_hash["Students"] += 1
        case account.profile.gender_id
        when 1
          s_hash["Female"] += 1
        when 2
          s_hash["Male"] += 1
        when 3
          s_hash["Non-Binary/Third Gender"] += 1
        when 4
          s_hash["Prefer to Self-Describe"] += 1
        when 5
          s_hash["Prefer Not to Say"] += 1
        end
        if account.profile.birth_date
          age = year - account.profile.birth_date.year
          case age
          when 0..4
            s_hash["Under 5"] += 1
          when 5..10
            s_hash["5 to 10"] += 1
          when 11..13
            s_hash["11 to 13"] += 1
          when 14..17
            s_hash["14 to 17"] += 1
          when 18..21
            s_hash["18 to 21"] += 1
          when 22..100
            s_hash["Over 21"] += 1
          end
        end
        if account.profile.ethnicity_id
          case account.profile.ethnicity_id
          when 1
            s_hash["American Indian or Alaska Native"] += 1
          when 2
            s_hash["Asian"] += 1
          when 3
            s_hash["Black or African American"] += 1
          when 4
            s_hash["Hispanic, Latino/a, or Spanish origin"] += 1
          when 5
            s_hash["Native Hawaiian or Other Pacific Islander"] += 1
          when 6
            s_hash["White"] += 1
          when 7
            s_hash["Two or More Races"] += 1
          when 8
            s_hash["Decline to Answer"] += 1
          when 9
            s_hash["Middle Eastner or North African"] += 1
          end
        end
      when "general"
        s_hash["General Users"] += 1
      end
    end

    def demographicsHash(scoped)
      for s in scoped do
        @data[s.id] = Hash.new
        s_hash = @data[s.id]
        s_hash["name"] = s.name
        s_hash["id"] = s.id
        if @scope == "site"
          s_hash["Educator Code"] = s.code
        end
        if @scope == "group"
          s_hash["Site Name"] = s.site.name
        end
        s_hash["Accounts"] = 0
        s_hash["Students"] = 0
        s_hash["Educators"] = 0
        s_hash["General Users"] = 0
        s_hash["Female"] = 0
        s_hash["Male"] = 0
        s_hash["Non-Binary/Third Gender"] = 0
        s_hash["Prefer to Self-Describe"] = 0
        s_hash["Prefer Not to Say"] = 0
        s_hash["Evidence Records"] = 0
        s_hash["Evidence Records Saved"] = 0
        s_hash["Evidence Records Submitted"] = 0
        s_hash["Collaborators"] = 0
        s_hash["Under 5"] = 0
        s_hash["5 to 10"] = 0
        s_hash["11 to 13"] = 0
        s_hash["14 to 17"] = 0
        s_hash["18 to 21"] = 0
        s_hash["Over 21"] = 0
        s_hash["American Indian or Alaska Native"] = 0
        s_hash["Asian"] = 0
        s_hash["Black or African American"] = 0
        s_hash["Hispanic, Latino/a, or Spanish origin"] = 0
        s_hash["Native Hawaiian or Other Pacific Islander"] = 0
        s_hash["White"] = 0
        s_hash["Two or More Races"] = 0
        s_hash["Decline to Answer"] = 0
        s_hash["Middle Eastner or North African"] = 0
      end
    end

    def populateByScoped(scoped)
      demographicsHash(scoped)

      case @scope
      when "network", "site"
        accounts = User.includes(:profile, :role, :sites).all
      when "group"
        accounts = User.includes(:profile, :role, :groups).all
      end

      for account in accounts do
        for s in scoped do
          account_in_s = false

          case @scope
          when "network", "site"
            for account_site in account.sites do

              case @scope
              when "network"
                for network_site in s.sites do
                  if account_site == network_site
                    account_in_s = true
                    break
                  end
                end
              when "site"
                if account_site == s
                  account_in_s = true
                end
              end

              if account_in_s
                countAccount(account, @data[s.id])
                break
              end
            end
          when "group"
            for account_grp in account.groups do
              if account_grp == s
                countAccount(account, @data[s.id])
              end
            end
          end

        end
      end

    end


end
