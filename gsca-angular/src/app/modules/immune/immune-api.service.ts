import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { BaseHttpService } from 'src/app/shared/base-http.service';
import { ExprSearch } from 'src/app/shared/model/exprsearch';

@Injectable({
  providedIn: 'root',
})
export class ImmuneApiService extends BaseHttpService {
  constructor(http: HttpClient) {
    super(http);
  }
  public getResourcePlotBlob(uuidname: string, plotType = 'png'): Observable<any> {
    return this.getDataImage('resource/responseplot/' + uuidname + '.' + plotType);
  }
  public getResourcePlotURL(uuidname: string, plotType = 'pdf'): string {
    return this.generateRoute('resource/responseplot/' + uuidname + '.' + plotType);
  }
  public getResourceTable(coll: string, uuidname: string): Observable<any> {
    return this.getData('resource/responsetable/' + coll + '/' + uuidname);
  }

  // immune cnv
  public getImmCnvCorTable(postTerm: ExprSearch): Observable<any> {
    return this.postData('immune/immunecnv/immcnvcortable', postTerm);
  }
  public getImmCnvCorPlot(postTerm: ExprSearch): Observable<any> {
    return this.postData('immune/immunecnv/immcnvcorplot', postTerm);
  }
  public getImmCnvCorSingleGene(postTerm: ExprSearch): Observable<any> {
    return this.postData('immune/immunecnv/immcnvcorsinglegene', postTerm);
  }
  // immune and gene set cnv
  public getGeneSetCNVAnalysis(postTerm: ExprSearch): Observable<any> {
    return this.postData('mutation/cnvsurvival/cnvgeneset', postTerm);
  }
  public getCnvImmGenesetCorPlot(uuidname: string): Observable<any> {
    return this.getData('immune/immunecnv/immcnvgenesetcorplot/' + uuidname);
  }
  public getImmCnvGenesetCorSingleGene(uuidname: string, cancertype: string, surType: string): Observable<any> {
    return this.getData('immune/immunecnv/immcnvgenesetcorsinglegeneplot/' + uuidname + '/' + cancertype + '/' + surType);
  }
  // immune and gene set cnv
  public getGeneSetSNVAnalysis(postTerm: ExprSearch): Observable<any> {
    return this.postData('mutation/snvsurvival/snvgeneset', postTerm);
  }
  public getSnvImmGenesetCorPlot(uuidname: string): Observable<any> {
    return this.getData('immune/immunesnv/immsnvgenesetcorplot/' + uuidname);
  }
  public getImmSnvGenesetCorSingleGene(uuidname: string, cancertype: string, surType: string): Observable<any> {
    return this.getData('immune/immunesnv/immsnvgenesetcorsinglegeneplot/' + uuidname + '/' + cancertype + '/' + surType);
  }
  // immune expression
  public getImmExprCorTable(postTerm: ExprSearch): Observable<any> {
    return this.postData('immune/immuneexpr/immexprcortable', postTerm);
  }
  public getImmExprCorPlot(postTerm: ExprSearch): Observable<any> {
    return this.postData('immune/immuneexpr/immexprcorplot', postTerm);
  }
  public getImmExprCorSingleGene(postTerm: ExprSearch): Observable<any> {
    return this.postData('immune/immuneexpr/immexprcorsinglegene', postTerm);
  }
  // immune snv
  public getImmSnvCorTable(postTerm: ExprSearch): Observable<any> {
    return this.postData('immune/immunesnv/immsnvcortable', postTerm);
  }
  public getImmSnvCorPlot(postTerm: ExprSearch): Observable<any> {
    return this.postData('immune/immunesnv/immsnvcorplot', postTerm);
  }
  public getImmSnvCorSingleGene(postTerm: ExprSearch): Observable<any> {
    return this.postData('immune/immunesnv/immsnvcorsinglegene', postTerm);
  }
  // immune methylation
  public getImmMethyCorTable(postTerm: ExprSearch): Observable<any> {
    return this.postData('immune/immunemethy/immmethycortable', postTerm);
  }
  public getImmMethyCorPlot(postTerm: ExprSearch): Observable<any> {
    return this.postData('immune/immunemethy/immmethycorplot', postTerm);
  }
  public getImmMethyCorSingleGene(postTerm: ExprSearch): Observable<any> {
    return this.postData('immune/immunemethy/immmethycorsinglegene', postTerm);
  }
  // GSVA immune
  public getGSVAAnalysis(postTerm: ExprSearch): Observable<any> {
    return this.postData('expression/gsva/gsvaanalysis', postTerm);
  }
  public getImmuGSVAPlot(uuidname: string): Observable<any> {
    return this.getData('immune/immuneexpr/immugsva/' + uuidname);
  }
  public getGSVAImmuSingleCellImage(uuidname: string, cancertype: string, surType: string): Observable<any> {
    return this.getData('immune/immuneexpr/immugsva/singlecell/' + uuidname + '/' + cancertype + '/' + surType);
  }
}
