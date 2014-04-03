class SettingsController < ApplicationController
  before_action :set_setting, only: [:show, :edit, :update, :destroy]
  before_action :set_settings
  
  # make sure this page cannot be edited by everyone
  http_basic_authenticate_with :name => 'admin', :password => ENV['SETTING_PASSWORD'], except: :index

  # GET /settings
  # GET /settings.json
  def index
  end

  # GET /settings/new
  def new
    @setting = Setting.new
  end

  # GET /settings/1/edit
  def edit
  end

  # POST /settings
  # POST /settings.json
  def create
    @setting = Setting.new(setting_params)

    respond_to do |format|
      if @setting.save
        format.html { redirect_to settings_url, notice: 'Setting was successfully created.' }
        format.json { render action: 'show', status: :created, location: @setting }
      else
        format.html { render action: 'new' }
        format.json { render json: @setting.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /settings/1
  # PATCH/PUT /settings/1.json
  def update
    respond_to do |format|
      if @setting.update(setting_params)
        format.html { redirect_to settings_url, notice: 'Setting was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @setting.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /settings/1
  # DELETE /settings/1.json
  def destroy
    @setting.destroy
    respond_to do |format|
      format.html { redirect_to settings_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_setting
      @setting = Setting.find(params[:id])
    end
    
    def set_settings
      @settings = Setting.all(order: :key)
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def setting_params
      params[:setting].permit(:key, :description, :value, :type)
    end
    
    def restrict
      
    end
end
