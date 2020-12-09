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

  // immune expression
  public getImmExprCorTable(postTerm: ExprSearch): Observable<any> {
    return this.postData('immune/immuneexpr/immexprcortable', postTerm);
  }
  public getImmExprCorPlot(postTerm: ExprSearch): Observable<any> {
    return this.postDataImage('immune/immuneexpr/immexprcorplot', postTerm);
  }
  public getImmExprCorSingleGene(postTerm: ExprSearch): Observable<any> {
    return this.postDataImage('immune/immuneexpr/immexprcorsinglegene', postTerm);
  }
  // immune snv
  public getImmSnvCorTable(postTerm: ExprSearch): Observable<any> {
    return this.postData('immune/immunesnv/immsnvcortable', postTerm);
  }
  public getImmSnvCorPlot(postTerm: ExprSearch): Observable<any> {
    return this.postDataImage('immune/immunesnv/immsnvcorplot', postTerm);
  }
  public getImmSnvCorSingleGene(postTerm: ExprSearch): Observable<any> {
    return this.postDataImage('immune/immunesnv/immsnvcorsinglegene', postTerm);
  }
  // immune methylation
  public getImmMethyCorTable(postTerm: ExprSearch): Observable<any> {
    return this.postData('immune/immunemethy/immmethycortable', postTerm);
  }
  public getImmMethyCorPlot(postTerm: ExprSearch): Observable<any> {
    return this.postDataImage('immune/immunemethy/immmethycorplot', postTerm);
  }
  public getImmMethyCorSingleGene(postTerm: ExprSearch): Observable<any> {
    return this.postDataImage('immune/immunemethy/immmethycorsinglegene', postTerm);
  }
}
