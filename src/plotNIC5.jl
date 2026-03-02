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
casename = "run_nea_hermione_LaPalma"
# casename = "run_nea_hermione_1way"

figdir = joinpath(ENV["GLOBALSCRATCH"], "figures/", casename)
mkpath(figdir)

# Read grid from grid files
gridfile1 = joinpath(datadir, "croco_grd_nea.nc")
gridfile2 = joinpath(datadir, "croco_grd_nea.nc.1")
gridfile3 = joinpath(datadir, "croco_grd_nea.nc.2")

# Create list of netCDF file
avgfilelist1 = Glob.glob("croco_canary_avg*.nc", joinpath(datadir, casename))
avgfilelist2 = Glob.glob("croco_canary_avg*.nc.1", joinpath(datadir, casename))
avgfilelist3 = Glob.glob("croco_canary_avg*.nc.2", joinpath(datadir, casename))


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

"""
    compute_surf_vorticity(resfile, grdfile)

Compute the normalised relative vorticity ζ = (∂v/∂x - ∂u/∂y) /f.
"""
function compute_surf_vorticity(resfile::String, grdfile::String)

    NCDataset(resfile) do ds_hist
        NCDataset(grdfile) do ds_grid

            # Load time vector
            thedates = ds_hist["time"][:]

            # Read 2D metrics correctly (keep as matrices)
            pm = ds_grid["pm"][:, :]   # 2D, rho-points
            pn = ds_grid["pn"][:, :]   # 2D, rho-points

            f = ds_grid["f"][:, :]

            u = ds_hist["u"][:, :, end, :]   # (xi_u, eta_u, s_rho) = (Lm, Mm+1, N)
            v = ds_hist["v"][:, :, end, :]   # (xi_v, eta_v, s_rho) = (Lm+1, Mm, N)

            Lm = size(u, 1)          # number of psi points in xi direction
            Mm = size(v, 2)          # number of psi points in eta direction
            ntimes = size(u, 3)

            zeta = zeros(eltype(u), Lm, Mm, ntimes)

            for k = 1:ntimes
                # ∂v/∂x at psi-points (difference in xi direction)
                # v[1:Lm+1, 1:Mm, k]  →  shape (Lm+1, Mm)
                pm_avg_x = @views (pm[1:Lm, 1:Mm] + pm[2:Lm+1, 1:Mm]) / 2   # (Lm, Mm)
                dvdx = @views (v[2:Lm+1, 1:Mm, k] - v[1:Lm, 1:Mm, k]) .* pm_avg_x

                # ∂u/∂y at psi-points (difference in eta direction)
                # u[1:Lm, 1:Mm+1, k]  →  shape (Lm, Mm+1)
                pn_avg_y = @views (pn[1:Lm, 1:Mm] + pn[1:Lm, 2:Mm+1]) / 2   # (Lm, Mm)
                dudy = @views (u[1:Lm, 2:Mm+1, k] - u[1:Lm, 1:Mm, k]) .* pn_avg_y

                # Both dvdx and dudy are now (Lm, Mm) → subtract
                @views zeta[:, :, k] .= dvdx .- dudy ./ f[1:end-1, 1:end-1]
            end
            replace!(zeta, 0.0 => NaN)

            return thedates::Vector{DateTime}, zeta::Array{Float32,3}
            
        end
    end


end

lon1, lat1 = load_grid(gridfile1)
lon2, lat2 = load_grid(gridfile2)
lon3, lat3 = load_grid(gridfile3)

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

    ax.title = Dates.format(thedate, "yyyy-mm-dd HH:MM:SS")
    xlims!(ax, -20.0, -9.0)
    ylims!(ax, 24.0, 33.0)
    ax.xticks = collect(-50.0:2:0.0)
    ax.yticks = collect(20.0:2.0:45.0)

    sf = surface!(ax, lon, lat, zeros(size(lon)), color=T,
    colormap = reverse(ColorSchemes.RdYlBu),
    colorrange = [23.0, 25.],
    shading = NoShading,
    nan_color = :gray,
    interpolate = false,)

    cb = Colorbar(fig[1, 2], sf, label = "T (°C)", labelrotation = 0, height = @lift($(pixelarea(ax.scene)).widths[2]))
    save(figname, fig)
    
    return nothing
end

function plot_vort(fig, ax, lon::Matrix{Float64}, lat::Matrix{Float64}, vort::Matrix{Float32}, thedate::DateTime, figname::AbstractString)
     ax.title = "Relative vorticity\n $(thedate)"
    
    sf = surface!(
        ax,
        lon,
        lat,
        vort,
        colormap = :curl,
        shading = NoShading,
        nan_color = :gray,
        interpolate = false,
        colorrange = (-1.5, 1.5),
    )
    Colorbar(
        fig[1, 2],
        sf,
        label = "ζ/f",
        labelrotation = 0,
        height = @lift($(pixelarea(ax.scene)).widths[2])
    )
    save(figname, fig)
    delete!(ax, sf)  
end

for datafile in avgfilelist3[1:27]
    @info("Working on file $(datafile)")

    


    #xlims!(ax, -21., -7.)
    #ylims!(ax, 23., 32.)
    #xlims!(ax, -20., -9.)
    #ylims!(ax, 24., 33.)

    for (ii, dd) in enumerate(thedates)

        @info("Working on date $(dd)")
        datestring = Dates.format(dd, "yyyymmdd_HHMMSS")
        @info(datestring)

        figname = joinpath(figdir, "SST_" * datestring * ".png")

        fig = Figure(size=(800, 800))
        ax = GeoAxis(fig[1, 1], dest = "+proj=merc")
        #, xgridcolor = :gray, 
        #xgridwidth = 0.5, xgridstyle = :dash, ygridcolor = :gray, 
        #ygridwidth = 0.5, ygridstyle = :dash,)

        if casename == "run_nea_hermione_LaPalma"
            hidedecorations!(ax)
        end
        
        plot_temp(fig, ax, lon3, lat3, T[:,:,ii], dd, figname)

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

# for datafile in avgfilelist2[6:end]
#     @info("Working on file $(datafile)")

#     thedates, T = extract_T(datafile);

#     fig = Figure(size=(800, 800))
#     ax = GeoAxis(fig[1, 1], dest = "+proj=merc", xgridcolor = :gray, 
#     xgridwidth = 0.5, xgridstyle = :dash, ygridcolor = :gray, 
#     ygridwidth = 0.5, ygridstyle = :dash,)

#     #xlims!(ax, -21., -7.)
#     #ylims!(ax, 23., 32.)
#     xlims!(ax, -20., -9.)
#     ylims!(ax, 24., 33.)

#     for (ii, dd) in enumerate(thedates)

#         @info("Working on date $(dd)")
#         datestring = Dates.format(dd, "yyyymmdd_HHMMSS")
#         @info(datestring)

#         figname = joinpath(figdir, "SST_" * datestring * "_nest.png")

#         plot_temp(fig, ax, lon2, lat2, T[:,:,ii], dd, figname)

#         # sf = surface!(ax, lon1, lat1, zeros(size(lon)), color=T[:,:,ii],
#         # colormap = reverse(ColorSchemes.RdYlBu),
#         # colorrange = [16.0, 23.],
#         # shading = NoShading,
#         # nan_color = :gray,
#         # interpolate = false,)

#         # Colorbar(fig[1, 2], sf, label = "T (°C)", labelrotation = 0, height = @lift($(pixelarea(ax.scene)).widths[2]))
#         # save(figname, fig)


#     end
# end
