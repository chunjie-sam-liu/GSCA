import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { BaseHttpService } from 'src/app/shared/base-http.service';
import { DegTableRecord } from 'src/app/shared/model/degtablerecord';
import { ExprSearch } from 'src/app/shared/model/exprsearch';

@Injectable({
  providedIn: 'root',
})
export class ExpressionApiService extends BaseHttpService {
  constructor(http: HttpClient) {
    super(http);
  }

  public getResourcePlotBlob(uuidname: string, plotType = 'png'): Observable<any> {
    return this.getDataImage('resource/responseplot/' + uuidname + '.' + plotType);
  }
  public getResourcePlotURL(uuidname: string, plotType = 'pdf'): string {
    return this.generateRoute('resource/responseplot/' + uuidname + '.' + plotType);
  }

  public getDEGTable(postTerm: ExprSearch): Observable<any> {
    return this.postData('expression/deg/degtable', postTerm);
  }
  public getDEGPlot(postTerm: ExprSearch): Observable<any> {
    return this.postData('expression/deg/degplot', postTerm);
  }

  public getGSVAAnalysis(postTerm: ExprSearch): Observable<any> {
    return this.postData('expression/geneset/gsvaanalysis', postTerm);
  }
  public getExprGSVAPlot(uuidname: string): Observable<any> {
    return this.getData('expression/geneset/exprgsvaplot/' + uuidname);
  }

  public getDEGSingleGenePlot(postTerm: ExprSearch): Observable<any> {
    return this.postData('expression/deg/degplot/single/gene', postTerm);
  }
  public getDEGSingleCancerTypePlot(postTerm: ExprSearch): Observable<any> {
    return this.postData('expression/deg/degplot/single/cancertype', postTerm);
  }
  public getDegGsvaTable(postTerm: ExprSearch): Observable<any> {
    return this.postDataImage('expression/deg/deggsva', postTerm);
  }
  public getSurvivalTable(postTerm: ExprSearch): Observable<any> {
    return this.postData('expression/survival/survivaltable', postTerm);
  }
  public getSurvivalPlot(postTerm: ExprSearch): Observable<any> {
    return this.postData('expression/survival/survivalplot', postTerm);
  }
  public getSurvivalSingleGenePlot(postTerm: ExprSearch): Observable<any> {
    return this.postData('expression/survival/single/gene', postTerm);
  }
  public getSubtypeTable(postTerm: ExprSearch): Observable<any> {
    return this.postData('expression/subtype/subtypetable', postTerm);
  }
  public getSubtypePlot(postTerm: ExprSearch): Observable<any> {
    return this.postData('expression/subtype/subtypeplot', postTerm);
  }
  public getSubtypeSingleGenePlot(postTerm: ExprSearch): Observable<any> {
    return this.postData('expression/subtype/single/gene', postTerm);
  }
  public getStageTable(postTerm: ExprSearch): Observable<any> {
    return this.postData('expression/stage/stagetable', postTerm);
  }
  public getStagePlot(postTerm: ExprSearch): Observable<any> {
    return this.postData('expression/stage/stageplot', postTerm);
  }
  public getStageSingleGenePlot(postTerm: ExprSearch): Observable<any> {
    return this.postData('expression/stage/single/gene', postTerm);
  }
}
