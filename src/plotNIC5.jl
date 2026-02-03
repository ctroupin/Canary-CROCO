using NCDatasets
using CairoMakie
using GeoMakie
using Dates
using GeoDatasets
using ColorSchemes
using Glob

datadir = joinpath(ENV["GLOBALSCRATCH"], "CROCO_FILES")
casename = "run_nea_hermione"
casename = "run_nea_hermione_1way"

figdir = joinpath(ENV["GLOBALSCRATCH"], "figures/", casename)
mkpath(figdir)


# Read grid from grid files
gridfile1 = joinpath(datadir, "croco_grd_nea.nc")
gridfile2 = joinpath(datadir, "croco_grd_nea.nc.1")

# Create list of netCDF file
avgfilelist1 = Glob.glob("croco_canary_avg*.nc", joinpath(datadir, casename))
avgfilelist2 = Glob.glob("croco_canary_avg*.nc.1", joinpath(datadir, casename))

function load_grid(gridfile::AbstractString)
    NCDataset(gridfile) do ds
        lon = ds["lon_rho"][:,:]
        lat = ds["lat_rho"][:,:]
        return lon::Matrix{Float64}, lat::Matrix{Float64}
    end
end

function extract_T(resfile::AbstractString)

    NCDataset(resfile) do nc
        thedates = nc["time"][:]
        T = nc["temp"][:,:,end,:]
        T[T.==0] .= NaN
        return thedates::Vector{DateTime}, T::Array{Float32, 3}
    end
end

lon1, lat1 = load_grid(gridfile1)
lon2, lat2 = load_grid(gridfile2)

# Extract land/sea mask and coastline
# lon_landsea, lat_landsea, landsea = GeoDatasets.landseamask(; resolution = 'f', grid = 1.25)
# landsea[landsea.==2] .= 1;
# landsea = Float64.(landsea)
# landsea[landsea.==0] .= NaN;
# 
# coordscoast = GeoDatasets.gshhg("f", 1);
# 
# goodlon = findall((lon_landsea .<= maximum(lon1)) .& (lon_landsea .>= minimum(lon1)))
# goodlat = findall((lat_landsea .<= maximum(lat1)) .& (lat_landsea .>= minimum(lat1)))
# lon_landsea = lon_landsea[goodlon]
# lat_landsea = lat_landsea[goodlat]
# landsea = landsea[goodlon, goodlat];

function plot_temp(fig, ax, lon::Matrix{Float64}, lat::Matrix{Float64}, T::Matrix{Float32}, thedate::DateTime, figname::AbstractString)

    # fig = Figure(size=(800, 800))
    # ax = GeoAxis(fig[1, 1], title=Dates.format(thedate, "yyyy-mm-dd HH:MM:SS"), dest = "+proj=merc", xgridcolor = :gray, 
    # xgridwidth = 0.5, xgridstyle = :dash, ygridcolor = :gray, 
    # ygridwidth = 0.5, ygridstyle = :dash,)

    # xlims!(ax, -21., -7.)
    # ylims!(ax, 23., 32.)
    ax.title = Dates.format(thedate, "yyyy-mm-dd HH:MM:SS")
    sf = surface!(ax, lon, lat, zeros(size(lon)), color=T,
    colormap = reverse(ColorSchemes.RdYlBu),
    colorrange = [18.0, 25.5],
    shading = NoShading,
    nan_color = :gray,
    interpolate = false,)

    Colorbar(fig[1, 2], sf, label = "T (°C)", labelrotation = 0, height = @lift($(pixelarea(ax.scene)).widths[2]))
    save(figname, fig)
    delete!(ax, sf)     

    return nothing
end

@info("Saving figure in directory $(figdir)");

for datafile in avgfilelist1[6:end]
    @info("Working on file $(datafile)")

    thedates, T = extract_T(datafile);

    fig = Figure(size=(800, 800))
    ax = GeoAxis(fig[1, 1], dest = "+proj=merc", xgridcolor = :gray, 
    xgridwidth = 0.5, xgridstyle = :dash, ygridcolor = :gray, 
    ygridwidth = 0.5, ygridstyle = :dash,)

    #xlims!(ax, -21., -7.)
    #ylims!(ax, 23., 32.)
    xlims!(ax, -20., -9.)
    ylims!(ax, 24., 33.)

    for (ii, dd) in enumerate(thedates)

        @info("Working on date $(dd)")
        datestring = Dates.format(dd, "yyyymmdd_HHMMSS")
        @info(datestring)

        figname = joinpath(figdir, "SST_" * datestring * ".png")

        plot_temp(fig, ax, lon1, lat1, T[:,:,ii], dd, figname)

        # sf = surface!(ax, lon1, lat1, zeros(size(lon)), color=T[:,:,ii],
        # colormap = reverse(ColorSchemes.RdYlBu),
        # colorrange = [16.0, 23.],
        # shading = NoShading,
        # nan_color = :gray,
        # interpolate = false,)

        # Colorbar(fig[1, 2], sf, label = "T (°C)", labelrotation = 0, height = @lift($(pixelarea(ax.scene)).widths[2]))
        # save(figname, fig)


    end
end

for datafile in avgfilelist2[6:end]
    @info("Working on file $(datafile)")

    thedates, T = extract_T(datafile);

    fig = Figure(size=(800, 800))
    ax = GeoAxis(fig[1, 1], dest = "+proj=merc", xgridcolor = :gray, 
    xgridwidth = 0.5, xgridstyle = :dash, ygridcolor = :gray, 
    ygridwidth = 0.5, ygridstyle = :dash,)

    #xlims!(ax, -21., -7.)
    #ylims!(ax, 23., 32.)
    xlims!(ax, -20., -9.)
    ylims!(ax, 24., 33.)

    for (ii, dd) in enumerate(thedates)

        @info("Working on date $(dd)")
        datestring = Dates.format(dd, "yyyymmdd_HHMMSS")
        @info(datestring)

        figname = joinpath(figdir, "SST_" * datestring * "_nest.png")

        plot_temp(fig, ax, lon2, lat2, T[:,:,ii], dd, figname)

        # sf = surface!(ax, lon1, lat1, zeros(size(lon)), color=T[:,:,ii],
        # colormap = reverse(ColorSchemes.RdYlBu),
        # colorrange = [16.0, 23.],
        # shading = NoShading,
        # nan_color = :gray,
        # interpolate = false,)

        # Colorbar(fig[1, 2], sf, label = "T (°C)", labelrotation = 0, height = @lift($(pixelarea(ax.scene)).widths[2]))
        # save(figname, fig)


    end
end
