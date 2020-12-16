import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { BaseHttpService } from 'src/app/shared/base-http.service';
import { ExprSearch } from 'src/app/shared/model/exprsearch';

@Injectable({
  providedIn: 'root',
})
export class DrugApiService extends BaseHttpService {
  constructor(http: HttpClient) {
    super(http);
  }

  public getResourcePlotBlob(uuidname: string, plotType = 'png'): Observable<any> {
    return this.getDataImage('resource/responseplot/' + uuidname + '.' + plotType);
  }
  public getResourcePlotURL(uuidname: string, plotType = 'pdf'): string {
    return this.generateRoute('resource/responseplot/' + uuidname + '.' + plotType);
  }
  // GDSC
  public getGDSCTable(postTerm: ExprSearch): Observable<any> {
    return this.postData('drug/gdsc/gdsctable', postTerm);
  }
  public getGDSCPlot(postTerm: ExprSearch): Observable<any> {
    return this.postData('drug/gdsc/gdscplot', postTerm);
  }
  public getGDSCSingleGenePlot(postTerm: ExprSearch): Observable<any> {
    return this.postData('drug/gdsc/single/gene', postTerm);
  }
  // CTRP
  public getCTRPTable(postTerm: ExprSearch): Observable<any> {
    return this.postData('drug/ctrp/ctrptable', postTerm);
  }
  public getCTRPPlot(postTerm: ExprSearch): Observable<any> {
    return this.postData('drug/ctrp/ctrpplot', postTerm);
  }
  public getCTRPSingleGenePlot(postTerm: ExprSearch): Observable<any> {
    return this.postData('drug/ctrp/single/gene', postTerm);
  }
}
