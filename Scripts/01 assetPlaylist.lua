local defaultConfig = {
    playlistCover = {
        default = "/Themes/" .. THEME:GetCurThemeName() .. "/Graphics/playlistCovers/_fallback.jpg",
        ["Favorites"] = "/Themes/" .. THEME:GetCurThemeName() .. "/Graphics/playlistCovers/_fallback.jpg",
    },
        
}

PlaylistCoverfallbackAsset = "Assets/Avatars/_fallback.png"
curPlaylistSelected = "Favorites"
playlistAssetFolder = "/Themes/" .. THEME:GetCurThemeName() .. "/Graphics/playlistCovers/"


playListCovers = create_setting("playlistAssetsConfig", "playlistAssetsConfig.lua", defaultConfig, 0)
playListCovers:load()