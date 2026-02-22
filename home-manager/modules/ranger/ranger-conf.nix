{ ... }:

{
  xdg.configFile."ranger/rc.conf".text = ''
    set preview_script ~/.config/ranger/scope.sh
    set use_preview_script true
    set colorscheme poimandres
    
    unmap f
    unmap /
    unmap <C-f>
    unmap <C-g>
    unmap dd
    unmap yy
    unmap r
    unmap a
    unmap t
    unmap T
    unmap x
    unmap X
    unmap dD
    unmap <DELETE>

    set save_tabs_on_exit true
    set column_ratios 1,2,4
    set draw_borders both
    set show_hidden true
    set confirm_on_delete always
    set automatically_count_files true
    set open_all_images true
    set preview_images true
    set preview_images_method kitty
    set preview_directories true
    set collapse_preview true
    set display_size_in_main_column false
    set display_size_in_status_bar true
    set display_free_space_in_status_bar false
    default_linemode devicons
    set preview_max_size 0

    map / console filter
    map f fzf_locate
    map g fzf_grep
    map G fzf_git_diff
    map F fzf_history

    map i action i
    map p action p
    map P action P
    map u action u
    map r action r
    map m action m
    map dD console shell echo "Disabled: Use action d"
    map dd action d
    map J scroll_preview 2
    map K scroll_preview -2
    map N scroll_preview 1000
    map P scroll_preview -1000
    map H history_go -1
    map L history_go 1
    map <CR> action e
    map a console action 

    map x exec_file
    map t sync_het
  '';

  xdg.configFile."ranger/rifle.conf".text = ''
    mime ^image, has imv,      X, flag f = imv -- "$@"
    mime ^image, has feh,      X, flag f = feh -- "$@"
    mime ^image, X, flag f = kitty +kitten icat "$@"
    ext pdf, has sioyek, X, flag f = sioyek -- "$@"
    ext pdf, has zathura, X, flag f = zathura -- "$@"
    ext md, has glow = glow -p "$@"
    mime ^text,  label editor = hx "$@"
    !mime ^text, label editor, ext xml|json|csv|py|sh|nix = hx "$@"
    else = hx "$@"
  '';

  xdg.configFile."ranger/ops_action.py".source = ./ops_action.py;
}
