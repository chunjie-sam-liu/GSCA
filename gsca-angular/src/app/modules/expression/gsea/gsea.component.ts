import { AfterViewInit, Component, Input, OnChanges, OnInit, SimpleChanges, ViewChild } from '@angular/core';
import { ExprSearch } from 'src/app/shared/model/exprsearch';
import { ExpressionApiService } from '../expression-api.service';
import collectionList from 'src/app/shared/constants/collectionlist';
import { MatTableDataSource } from '@angular/material/table';
import { GSEATableRecord } from 'src/app/shared/model/gseatablerecord';
import { MatPaginator } from '@angular/material/paginator';
import { MatSort } from '@angular/material/sort';

@Component({
  selector: 'app-gsea',
  templateUrl: './gsea.component.html',
  styleUrls: ['./gsea.component.css'],
})
export class GseaComponent implements OnInit, OnChanges, AfterViewInit {
  @Input() searchTerm: ExprSearch;

  dataSourceGSEALoading = true;
  dataSourceGSEA: MatTableDataSource<GSEATableRecord>;
  showGSEATable = true;
  @ViewChild('paginatorGSEA') paginatorGSEA: MatPaginator;
  @ViewChild(MatSort) sortGSEA: MatSort;
  displayedColumnsGSEA = ['cancertype'];
  displayedColumnsGSVAHeader = ['Cancer type'];

  GSEAImage: any;
  GSEAPdfURL: string;
  GSEAImageLoading = true;
  showGSEAImage = true;

  constructor(private expressionApiService: ExpressionApiService) {}

  ngOnInit(): void {}

  ngOnChanges(changes: SimpleChanges): void {
    this.dataSourceGSEALoading = true;
    this.GSEAImageLoading = true;
    const postTerm = this._validCollection(this.searchTerm);

    if (!postTerm.validColl.length) {
      this.dataSourceGSEALoading = false;
      this.GSEAImageLoading = false;
      this.showGSEATable = false;
      this.showGSEAImage = false;
    } else {
    }
  }

  ngAfterViewInit(): void {}

  private _validCollection(st: ExprSearch): any {
    st.validColl = st.cancerTypeSelected
      .map((val) => {
        return collectionList.deg.collnames[collectionList.deg.cancertypes.indexOf(val)];
      })
      .filter(Boolean);
    return st;
  }

  private _createImageFromBlob(res: Blob, present: string) {
    const reader = new FileReader();
    reader.addEventListener(
      'load',
      () => {
        switch (present) {
          case 'GSEAImage':
            this.GSEAImage = reader.result;
            break;
        }
      },
      false
    );
    if (res) {
      reader.readAsDataURL(res);
    }
  }

  public applyFilter(event: Event) {
    const filterValue = (event.target as HTMLInputElement).value;
    this.dataSourceGSEA.filter = filterValue.trim().toLowerCase();

    if (this.dataSourceGSEA.paginator) {
      this.dataSourceGSEA.paginator.firstPage();
    }
  }
}
