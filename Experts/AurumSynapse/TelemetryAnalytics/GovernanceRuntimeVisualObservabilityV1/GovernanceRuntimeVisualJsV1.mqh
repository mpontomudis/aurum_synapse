//+------------------------------------------------------------------+
//| GovernanceRuntimeVisualJsV1.mqh                                 |
//| Vanilla table sort + collapsible (no external deps)              |
//+------------------------------------------------------------------+
#ifndef __AURUM_GOV_RUNTIME_VISUAL_JS_V1_MQH__
#define __AURUM_GOV_RUNTIME_VISUAL_JS_V1_MQH__

inline string GovRuntimeVisualJsV1_Embedded(void)
{
   string j = "";
   j += "(function(){\n";
   j += "function sortTable(tableId,col){\n";
   j += " var t=document.getElementById(tableId); if(!t) return;\n";
   j += " var tb=t.tBodies[0]; var rows=Array.prototype.slice.call(tb.rows);\n";
   j += " var mult=(t.dataset.sortCol==String(col)&&t.dataset.sortDir==='asc')?-1:1;\n";
   j += " t.dataset.sortCol=String(col); t.dataset.sortDir=(mult>0)?'asc':'desc';\n";
   j += " rows.sort(function(a,b){\n";
   j += "  var x=a.cells[col].innerText.trim(); var y=b.cells[col].innerText.trim();\n";
   j += "  var nx=parseFloat(x.replace(/[^0-9.-]/g,'')); var ny=parseFloat(y.replace(/[^0-9.-]/g,''));\n";
   j += "  if(!isNaN(nx)&&!isNaN(ny)) return mult*(nx-ny);\n";
   j += "  return mult*x.localeCompare(y);\n";
   j += " });\n";
   j += " rows.forEach(function(r){tb.appendChild(r);});\n";
   j += "}\n";
   j += "window.govSort=function(id,c){sortTable(id,c);};\n";
   j += "window.govFilterRows=function(inpId,tableId){\n";
   j += " var inp=document.getElementById(inpId); var t=document.getElementById(tableId);\n";
   j += " if(!inp||!t||!t.tBodies[0]) return;\n";
   j += " var q=inp.value.toLowerCase(); var rows=t.tBodies[0].rows;\n";
   j += " for(var i=0;i<rows.length;i++){\n";
   j += "  var txt=rows[i].innerText.toLowerCase();\n";
   j += "  rows[i].style.display=(q.length===0||txt.indexOf(q)>=0)?'':'none';\n";
   j += " }\n";
   j += "}\n";
   j += "})();\n";
   return j;
}

#endif // __AURUM_GOV_RUNTIME_VISUAL_JS_V1_MQH__
