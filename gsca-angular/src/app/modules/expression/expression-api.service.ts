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
  public getResourceTable(coll: string, uuidname: string): Observable<any> {
    return this.getData('resource/responsetable/' + coll + '/' + uuidname);
  }

  public getResourcePlotURL(uuidname: string, plotType = 'pdf'): string {
    return this.generateRoute('resource/responseplot/' + uuidname + '.' + plotType);
  }

  // DEG
  public getDEGTable(postTerm: ExprSearch): Observable<any> {
    return this.postData('expression/deg/degtable', postTerm);
  }
  public getDEGPlot(postTerm: ExprSearch): Observable<any> {
    return this.postData('expression/deg/degplot', postTerm);
  }
  public getDEGSingleGenePlot(postTerm: ExprSearch): Observable<any> {
    return this.postData('expression/deg/degplot/single/gene', postTerm);
  }
  public getDEGSingleCancerTypePlot(postTerm: ExprSearch): Observable<any> {
    return this.postData('expression/deg/degplot/single/cancertype', postTerm);
  }
  // GSVA
  public getGSVAAnalysis(postTerm: ExprSearch): Observable<any> {
    return this.postData('expression/gsva/gsvaanalysis', postTerm);
  }
  public getExprGSVAPlot(uuidname: string): Observable<any> {
    return this.getData('expression/gsva/exprgsvaplot/' + uuidname);
  }
  // GSVA survival
  public getExprSurvivalGSVAPlot(uuidname: string): Observable<any> {
    return this.getData('expression/gsva/exprsurvivalgsva/' + uuidname);
  }
  public getGSVASurvivalSingleCancerImage(uuidname: string, cancertype: string, surType: string): Observable<any> {
    return this.getData('expression/gsva/survival/singlecancer/' + uuidname + '/' + cancertype + '/' + surType);
  }
  // GSVA stage
  public getExprStageGSVAPlot(uuidname: string): Observable<any> {
    return this.getData('expression/gsva/stage/' + uuidname);
  }
  public getGSVAStageSingleCancerImage(uuidname: string, cancertype: string): Observable<any> {
    return this.getData('expression/gsva/stage/singlecancer/' + uuidname + '/' + cancertype);
  }
  // GSEA
  public getGSEAAnalysis(postTerm: ExprSearch): Observable<any> {
    return this.postData('expression/gsea/gseaanalysis', postTerm);
  }
  public getExprGSEAPlot(uuidname: string): Observable<any> {
    return this.getData('expression/gsea/exprgseaplot/' + uuidname);
  }
  public getGSEASingleCancerTypePlot(uuidname: string, cancertype: string): Observable<any> {
    return this.getData('expression/gsea/single/cancertype/' + uuidname + '/' + cancertype);
  }

  public getDegGsvaTable(postTerm: ExprSearch): Observable<any> {
    return this.postDataImage('expression/deg/deggsva', postTerm);
  }

  // survival
  public getSurvivalTable(postTerm: ExprSearch): Observable<any> {
    return this.postData('expression/survival/survivaltable', postTerm);
  }
  public getSurvivalPlot(postTerm: ExprSearch): Observable<any> {
    return this.postData('expression/survival/survivalplot', postTerm);
  }
  public getSurvivalSingleGenePlot(postTerm: ExprSearch): Observable<any> {
    return this.postData('expression/survival/single/gene', postTerm);
  }

  // subtype
  public getSubtypeTable(postTerm: ExprSearch): Observable<any> {
    return this.postData('expression/subtype/subtypetable', postTerm);
  }
  public getSubtypePlot(postTerm: ExprSearch): Observable<any> {
    return this.postData('expression/subtype/subtypeplot', postTerm);
  }
  public getSubtypeSingleGenePlot(postTerm: ExprSearch): Observable<any> {
    return this.postData('expression/subtype/single/gene', postTerm);
  }

  // stage
  public getStageTable(postTerm: ExprSearch): Observable<any> {
    return this.postData('expression/stage/stagetable', postTerm);
  }
  public getStagePlot(postTerm: ExprSearch): Observable<any> {
    return this.postData('expression/stage/stageplot', postTerm);
  }
  public getStageHeatTrendPlot(postTerm: ExprSearch): Observable<any> {
    return this.postData('expression/stage/stageheattrendplot', postTerm);
  }
  public getStageSingleGenePlot(postTerm: ExprSearch): Observable<any> {
    return this.postData('expression/stage/single/gene', postTerm);
  }
}
