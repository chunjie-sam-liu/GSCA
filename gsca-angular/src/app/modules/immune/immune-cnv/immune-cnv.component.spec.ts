import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { ImmuneCnvComponent } from './immune-cnv.component';

describe('ImmuneCnvComponent', () => {
  let component: ImmuneCnvComponent;
  let fixture: ComponentFixture<ImmuneCnvComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ ImmuneCnvComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(ImmuneCnvComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
