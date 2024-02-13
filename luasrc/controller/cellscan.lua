module("luci.controller.cellscan", package.seeall)

function index()
    -- entry({"admin", "modem"}, firstchild(), _("蜂窝"), 25).dependent=false
    entry({"admin", "modem", "cellscan"}, template("cellscan/cellscan"), _("基站扫描"), 80).dependent = true
end


function parse_results()
    os.execute("/usr/share/modem/keyPairCellScan.sh")
    -- Read and parse cellinfo file
    local cellinfo = io.open("/tmp/kpcellinfo", "r")
    if cellinfo then
        for line in cellinfo:lines() do
            local mode, operator, earfcn, pci, rsrp, rsrq = line:match('+QSCAN: "(.-)",(.-),(.-),(.-),(.-),(.+)')
            if mode and operator and earfcn and pci and rsrp and rsrq then
                luci.template.render("cellscan/cellscan_row", {
                    mode = mode,
                    operator = operator,
                    earfcn = earfcn,
                    pci = pci,
                    rsrp = rsrp,
                    rsrq = rsrq
                })
            end
        end
        cellinfo:close()
    else
        luci.template.render("cellscan/cellscan_row", {
            mode = "无有效数据",
            operator = "",
            earfcn = "",
            pci = "",
            rsrp = "",
            rsrq = ""
        })
    end
end